import { cloudDatabase, cloudCommon } from '@kit.CloudFoundationKit';
import auth from '@hw-agconnect/auth';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { appStore } from '../store/AppStore';
import { ServerInfo } from '../model/ServerInfo';
import { CloudServer } from '../model/CloudServer';

const DOMAIN: number = 0x0000;
const TAG: string = 'CloudHistory';

/// AGC 存储区名（需在 AppGallery Connect 后台创建同名 Zone）
const ZONE_NAME: string = 'NoLetHistory';
const QUERY_LIMIT: number = 100;

export type CloudHistoryFailReason = 'not_logged_in' | 'failed';

export interface CloudHistoryResult {
  ok: boolean;
  reason?: CloudHistoryFailReason;
}

let appContext: common.Context | null = null;
let initialized: boolean = false;

/// 应用启动时调用：初始化 AGC Auth，并把其 AuthProvider 注入云开发服务。
/// json 为 agconnect-services.json 的文本内容
export function setupCloudHistory(context: common.Context, agcJson: string): void {
  appContext = context;
  auth.init(context.getApplicationContext(), agcJson);
  cloudCommon.init({ authProvider: auth.getAuthProvider() });
  initialized = true;
}

/// 确保有 AGC 登录用户：已登录（含匿名）直接复用，否则匿名登录（游客模式，静默无弹窗）
async function ensureLoggedIn(): Promise<boolean> {
  if (appContext === null) return false;
  try {
    const user = await auth.getCurrentUser();
    if (user !== null) return true;
    await auth.signInAnonymously();
    hilog.info(DOMAIN, TAG, 'signed in anonymously');
    return true;
  } catch (e) {
    hilog.error(DOMAIN, TAG, `ensure login failed: ${(e as BusinessError).code} ${(e as BusinessError).message}`);
    return false;
  }
}

function zone(): cloudDatabase.DatabaseZone {
  return cloudDatabase.zone(ZONE_NAME);
}

function currentUnionID(): string {
  return appStore.getState().huaweiUnionID;
}

function toCloudServer(server: ServerInfo): CloudServer {
  const record = new CloudServer();
  record.user = currentUnionID();
  record.key = server.key ?? '';
  record.url = server.url;
  record.createDate = new Date();
  return record;
}

/// 创建/重置服务器后同步一条到云端。失败不抛错，不影响本地主流程
export async function syncServer(server: ServerInfo): Promise<CloudHistoryResult> {
  if (!initialized || appContext === null) return { ok: false, reason: 'failed' };
  if (!currentUnionID()) {
    hilog.info(DOMAIN, TAG, 'sync skipped: not logged in');
    return { ok: false, reason: 'not_logged_in' };
  }
  if (!await ensureLoggedIn()) return { ok: false, reason: 'failed' };
  try {
    const record = toCloudServer(server);
    const count: number = await zone().upsert(record);
    hilog.info(DOMAIN, TAG, `synced ${record.url}/${record.key}, rows=${count}`);
    return { ok: true };
  } catch (e) {
    hilog.error(DOMAIN, TAG, `sync failed: ${(e as BusinessError).code} ${(e as BusinessError).message}`);
    return { ok: false, reason: 'failed' };
  }
}

/// 历史页打开时补偿同步：把本地当前全部服务器 upsert 一遍，补回添加时离线/失败的记录
export async function backfill(servers: ServerInfo[]): Promise<CloudHistoryResult> {
  if (!initialized || appContext === null) return { ok: false, reason: 'failed' };
  if (!currentUnionID()) {
    return { ok: false, reason: 'not_logged_in' };
  }
  if (servers.length === 0) return { ok: true };
  if (!await ensureLoggedIn()) return { ok: false, reason: 'failed' };
  try {
    const records: CloudServer[] = servers.map((s: ServerInfo): CloudServer => toCloudServer(s));
    const count: number = await zone().upsert(records);
    hilog.info(DOMAIN, TAG, `backfill ${records.length} servers, rows=${count}`);
    return { ok: true };
  } catch (e) {
    hilog.error(DOMAIN, TAG, `backfill failed: ${(e as BusinessError).code} ${(e as BusinessError).message}`);
    return { ok: false, reason: 'failed' };
  }
}

/// 拉取当前用户的历史服务器，按添加时间倒序
export async function fetchHistory(): Promise<CloudServer[]> {
  if (!initialized || !currentUnionID()) return [];
  if (!await ensureLoggedIn()) return [];
  const condition = new cloudDatabase.DatabaseQuery(CloudServer);
  condition.orderByDesc('createDate').limit(QUERY_LIMIT);
  return zone().query(condition);
}

/// 历史页删除单条记录
export async function deleteHistory(record: CloudServer): Promise<CloudHistoryResult> {
  try {
    await zone().delete(record);
    return { ok: true };
  } catch (e) {
    hilog.error(DOMAIN, TAG, `delete failed: ${(e as BusinessError).code} ${(e as BusinessError).message}`);
    return { ok: false, reason: 'failed' };
  }
}
