import { pushCommon, RemoteNotificationExtensionAbility } from '@kit.PushKit';
import { common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { parsePush, parseMergedDict, extractCipher, CipherPayload } from '../model/PushParser';
import { pendingAppendUpsert } from '../model/PendingStore';
import { readCryptoConfigsForContext } from '../store/AppPersistence';
import { decryptCiphertext } from '../tools/PushCipher';
import { resByName, displayGroup, defaultGroup } from '../tools/I18n';
import { applyPushCopy } from '../tools/PushClipboard';
import { Message } from '../model/Message';

const DOMAIN = 0x0000;
const TAG = 'RemoteNotificationExtAbility';

// 未传 cipherNumber 时默认使用密钥列表下标 0（系统内置项，与 iOS 一致）
const DEFAULT_CIPHER_INDEX: number = 0;

type PushDict = Record<string, Object>;

// 解密结果：ok+data 成功；drop=true 为无对应下标密钥，直接放弃展示与归档；ok=false 为解密失败
interface DecryptOutcome {
  ok: boolean;
  drop: boolean;
  data: PushDict | null;
}

// 通知消息在展示前到达这里：密文推送先按密钥列表解密，再解析自定义字段、改写标题/正文，
// 并归档到 PendingStore，主应用启动/回前台时 drain 入库
// （与 iOS NotificationService + DecryptionProcessor + ArchiveProcessor 对应）。
export default class RemoteNotificationExtAbility extends RemoteNotificationExtensionAbility {
  async onReceiveMessage(
    remoteNotificationInfo: pushCommon.RemoteNotificationInfo
  ): Promise<pushCommon.RemoteNotificationContent> {
    hilog.info(DOMAIN, TAG, `onReceiveMessage: ${remoteNotificationInfo.data}`);

    const context = this.context as common.Context;
    const merged = parseMergedDict(remoteNotificationInfo.data);
    if (!merged) {
      return this.emptyContent();
    }

    // 携带 ciphertext 即进入解密流程；解密出的 JSON（键统一小写）覆盖回推送字段后走正常解析
    const cipher: CipherPayload | null = extractCipher(merged);
    if (cipher) {
      const outcome: DecryptOutcome = await this.decryptPayload(context, cipher);
      if (outcome.drop) {
        // 需求约定：下标 0 密钥不存在（或指定下标越界）时直接返回
        return this.emptyContent();
      }
      if (!outcome.ok || !outcome.data) {
        // 对齐 iOS：解密失败时标题提示、正文展示原始密文，不归档
        return this.decryptFailedContent(context, cipher.text);
      }
      const data: PushDict = outcome.data;
      const keys = Object.keys(data);
      for (let i = 0; i < keys.length; i++) {
        merged[keys[i].toLowerCase()] = data[keys[i]];
      }
    }

    const result = parsePush(JSON.stringify(merged), defaultGroup(context));

    if (!result) {
      return this.emptyContent();
    }

    const msg = result.message;
    pendingAppendUpsert(context, msg);
    applyPushCopy(result.copy, msg);

    // ArkTS 禁止对象字面量直接赋给 Record，需经 JSON.parse 转换
    let parameters: Record<string, Object> = {};
    try {
      const json = `{"id":${JSON.stringify(msg.id)},"group":${JSON.stringify(msg.group)},`
        + `"url":${JSON.stringify(msg.url)}}`;
      parameters = JSON.parse(json) as Record<string, Object>;
    } catch (e) {
      hilog.error(DOMAIN, TAG, `build wantAgent parameters failed: ${(e as Error).message}`);
    }
    const wantAgent: pushCommon.RemoteWantAgent = {
      abilityName: 'EntryAbility',
      parameters,
    };
    const content: pushCommon.RemoteNotificationContent = {
      title: msg.title || displayGroup(context, msg.group),
      text: msg.body,
      wantAgent,
    };
    // badge 为角标绝对值：>0 设置，<=0 清除（setBadgeNumber，与 iOS aps.badge 语义一致）
    if (result.badge !== undefined) {
      content.setBadgeNumber = result.badge;
    }
    return content;
  }

  // 按 cipherNumber（缺省下标 0，系统内置项）取密钥列表中的配置解密
  private async decryptPayload(context: common.Context, cipher: CipherPayload): Promise<DecryptOutcome> {
    const configs = await readCryptoConfigsForContext(context);
    const index: number = cipher.index ?? DEFAULT_CIPHER_INDEX;
    if (index < 0 || index >= configs.length || !configs[index].key) {
      hilog.warn(DOMAIN, TAG, `cipher key index ${index} not found in ${configs.length} configs`);
      return { ok: false, drop: true, data: null };
    }

    const plain: string | null = await decryptCiphertext(cipher.text, configs[index].key);
    if (plain === null) {
      hilog.error(DOMAIN, TAG, `decrypt failed with key index ${index}`);
      return { ok: false, drop: false, data: null };
    }
    try {
      const parsed: Object = JSON.parse(plain);
      if (!parsed || typeof parsed !== 'object') {
        return { ok: false, drop: false, data: null };
      }
      return { ok: true, drop: false, data: parsed as PushDict };
    } catch (e) {
      hilog.error(DOMAIN, TAG, `decrypted payload is not JSON: ${(e as Error).message}`);
      return { ok: false, drop: false, data: null };
    }
  }

  private emptyContent(): pushCommon.RemoteNotificationContent {
    const content: pushCommon.RemoteNotificationContent = {};
    return content;
  }

  // 对齐 iOS 解密失败：标题「解密失败！」，正文展示原始密文，不归档
  private decryptFailedContent(context: common.Context, ciphertext: string):
    pushCommon.RemoteNotificationContent {
    const content: pushCommon.RemoteNotificationContent = {
      title: resByName(context, 'decrypt_failed'),
      text: ciphertext,
    };
    return content;
  }

  onDestroy(): void {
    hilog.info(DOMAIN, TAG, 'onDestroy');
  }
}
