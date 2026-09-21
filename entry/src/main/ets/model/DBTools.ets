import { relationalStore } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { Message } from './Message';

const DOMAIN = 0x0000;
const TAG = 'MessageStore';

@ObservedV2
export class GroupHead {
  @Trace head: Message;
  @Trace unread: number;
  @Trace count: number;

  constructor(head: Message, unread: number, count: number) {
    this.head = head;
    this.unread = unread;
    this.count = count;
  }
}

export interface Snapshot {
  total: number;
  unread: number;
  groups: GroupHead[];
}

// 对应 iOS MessageDBManager：upsert / 删除 / 已读 / 过期清理 / 分组快照。
// ponytail: 列表一次性读最近 200 条，上万条消息时改分页游标。
class MessageStoreImpl {
  private store: relationalStore.RdbStore | null = null;
  private readyPromise: Promise<void> | null = null;
  readonly PAGE_SIZE = 200;

  init(context: common.Context): Promise<void> {
    if (this.readyPromise) {
      return this.readyPromise;
    }
    this.readyPromise = (async (): Promise<void> => {
      const config: relationalStore.StoreConfig = {
        name: 'nolet.db',
        securityLevel: relationalStore.SecurityLevel.S1,
      };
      this.store = await relationalStore.getRdbStore(context, config);
      // 字段精简（iOS 对齐），旧版本表结构不一致直接丢弃重建，后续结构变更走 version + onUpgrade
      const version: number = this.store.version;
      if (version === 0) {
        await this.store.executeSql('DROP TABLE IF EXISTS messages');
      }
      await this.store.executeSql(CREATE_TABLE);
      await this.store.executeSql('CREATE INDEX IF NOT EXISTS idx_msg_date ON messages(createDate DESC)');
      await this.store.executeSql('CREATE INDEX IF NOT EXISTS idx_msg_group ON messages("group")');
      await this.store.executeSql('CREATE INDEX IF NOT EXISTS idx_msg_read ON messages(read)');
      this.store.version = 1;
    })();
    return this.readyPromise;
  }

  private db(): relationalStore.RdbStore {
    if (!this.store) {
      throw new Error('MessageStore not initialized');
    }
    return this.store;
  }

  private async ready(): Promise<void> {
    if (!this.readyPromise) {
      throw new Error('MessageStore not initialized');
    }
    await this.readyPromise;
  }

  // 相同 id 覆盖（INSERT OR REPLACE），新推送会重置 read，与 iOS apply(json) 一致
  async upsert(msg: Message): Promise<void> {
    await this.ready();
    await this.db().executeSql(
      `INSERT OR REPLACE INTO messages
       (id, createDate, "group", title, body, url, icon, image, ttl, read)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        msg.id, msg.createDate, msg.group, msg.title, msg.body,
        msg.url, msg.icon, msg.image, msg.ttl, msg.read ? 1 : 0,
      ]
    );
  }

  async delete(id: string): Promise<void> {
    await this.ready();
    await this.db().executeSql('DELETE FROM messages WHERE id = ?', [id]);
  }

  // 批量 upsert:值内联到 SQL(数据均为本应用生成),单批 100 行。
  // ponytail: 参数绑定走 IPC 编组,16000 个 ValueType 要几分钟;内联字面量只需 10 次 SQL 调用。
  async upsertBatch(messages: Message[]): Promise<void> {
    await this.ready();
    const quote = (s: string): string => `'${s.replace(/'/g, "''")}'`;
    const CHUNK = 100;
    for (let start = 0; start < messages.length; start += CHUNK) {
      const part = messages.slice(start, start + CHUNK);
      const tuples = part.map((m: Message): string =>
      `(${quote(m.id)},${m.createDate},${quote(m.group)},${quote(m.title)},`
        + `${quote(m.body)},${quote(m.url)},${quote(m.icon)},${quote(m.image)},`
        + `${m.ttl},${m.read ? 1 : 0})`);
      await this.db().executeSql(
        `INSERT OR REPLACE INTO messages
         (id, createDate, "group", title, body, url, icon, image, ttl, read) VALUES ${tuples.join(',')}`,
        []);
    }
  }

  async deleteGroup(group: string): Promise<void> {
    await this.ready();
    await this.db().executeSql('DELETE FROM messages WHERE "group" = ?', [group]);
  }

  async deleteAllRead(): Promise<void> {
    await this.ready();
    await this.db().executeSql('DELETE FROM messages WHERE read = 1');
  }

  async clear(): Promise<void> {
    await this.ready();
    await this.db().executeSql('DELETE FROM messages');
  }

  async deleteExpired(): Promise<void> {
    await this.ready();
    const now = Math.floor(Date.now() / 1000);
    await this.db().executeSql('DELETE FROM messages WHERE ttl > 0 AND ttl <= ?', [now]);
  }

  // 删除指定时间戳（秒）之前的全部消息
  async deleteBefore(timestampSec: number): Promise<void> {
    await this.ready();
    try {
      await this.db().executeSql('DELETE FROM messages WHERE createDate < ?', [timestampSec]);
    } catch (error) {
      console.error(error)
    }
  }

  async markAllRead(group?: string): Promise<void> {
    await this.ready();
    try {
      if (group) {
        await this.db().executeSql('UPDATE messages SET read = 1 WHERE "group" = ?', [group]);
      } else {
        await this.db().executeSql('UPDATE messages SET read = 1 WHERE read = 0');
      }
    } catch (error) {
      console.error(error)
    }
  }

  private count(sql: string): number {
    const rs = this.db().querySqlSync(sql);
    try {
      return rs.goToFirstRow() ? rs.getLong(rs.getColumnIndex('c')) : 0;
    } catch (error) {
      console.error(`查询失败: ${error}`);
      return 0
    } finally {
      try {
        rs.close();
      } catch {
        console.error("数据库关闭失败")
      }
    }
  }

  private rows(sql: string, args: relationalStore.ValueType[]): Message[] {
    const result: Message[] = [];
    const rs = this.db().querySqlSync(sql, args);
    try {
      while (rs.goToNextRow()) {
        result.push(Message.fromResultSet(rs));
      }
    } catch (error) {
      console.error(`查询失败: ${error}`);
      return []
    } finally {
      rs.close();
    }
    return result;
  }

  async latest(group?: string, limit: number = this.PAGE_SIZE): Promise<Message[]> {
    await this.ready();
    if (group) {
      return this.rows(
        `SELECT * FROM messages WHERE "group" = ? ORDER BY createDate DESC, id DESC LIMIT ?`,
        [group, limit]
      );
    }
    return this.rows(
      'SELECT * FROM messages ORDER BY createDate DESC, id DESC LIMIT ?',
      [limit]
    );
  }

  // 按主键 id 查单条；无结果返回 null
  async getById(id: string): Promise<Message | null> {
    await this.ready();
    const found: Message[] = this.rows('SELECT * FROM messages WHERE id = ? LIMIT 1', [id]);
    return found.length > 0 ? found[0] : null;
  }

  // ponytail: LIKE 全字段搜索，消息量上万后换 FTS 分词表
  async search(keyword: string, group?: string, limit: number = 50): Promise<Message[]> {
    await this.ready();
    const like = `%${keyword}%`;
    const cols: string[] = ['"group"', 'title', 'body', 'url'];
    const args: relationalStore.ValueType[] = cols.map((): string => like);
    let sql = `SELECT * FROM messages WHERE (${cols.map(c => `${c} LIKE ?`).join(' OR ')})`;
    if (group) {
      sql += ' AND "group" = ?';
      args.push(group);
    }
    sql += ' ORDER BY createDate DESC, id DESC LIMIT ?';
    args.push(limit);
    return this.rows(sql, args);
  }

  async snapshot(): Promise<Snapshot> {
    await this.ready();
    const total = this.count('SELECT COUNT(*) c FROM messages');
    const unread = this.count('SELECT COUNT(*) c FROM messages WHERE read = 0');

    const heads = this.rows(
      `SELECT * FROM messages m
       WHERE id = (SELECT id FROM messages WHERE "group" = m."group"
                   ORDER BY createDate DESC, id DESC LIMIT 1)
       ORDER BY createDate DESC, id DESC`,
      []
    );
    const unreadMap = new Map<string, number>();
    const countMap = new Map<string, number>();
    const ur = this.db().querySqlSync(
      'SELECT "group" g, COUNT(*) c FROM messages WHERE read = 0 GROUP BY "group"'
    );
    try {
      while (ur.goToNextRow()) {
        unreadMap.set(ur.getString(ur.getColumnIndex('g')), ur.getLong(ur.getColumnIndex('c')));
      }
    } finally {
      ur.close();
    }
    const cr = this.db().querySqlSync(
      'SELECT "group" g, COUNT(*) c FROM messages GROUP BY "group"'
    );
    try {
      while (cr.goToNextRow()) {
        countMap.set(cr.getString(cr.getColumnIndex('g')), cr.getLong(cr.getColumnIndex('c')));
      }
    } finally {
      cr.close();
    }

    const groups: GroupHead[] = heads.map((head: Message): GroupHead => {
      return new GroupHead(
        head,
        unreadMap.get(head.group) ?? 0,
        countMap.get(head.group) ?? 0
      );
    });
    hilog.info(DOMAIN, TAG, `snapshot total=${total} unread=${unread} groups=${groups.length}`);
    return { total, unread, groups };
  }
}

export const messageStore = new MessageStoreImpl();

const CREATE_TABLE = `
CREATE TABLE IF NOT EXISTS messages (
  id TEXT PRIMARY KEY NOT NULL,
  createDate INTEGER NOT NULL,
  "group" TEXT NOT NULL DEFAULT '默认',
  title TEXT,
  body TEXT,
  url TEXT,
  icon TEXT,
  image TEXT,
  ttl INTEGER NOT NULL DEFAULT -1,
  read INTEGER NOT NULL DEFAULT 0
)`;
