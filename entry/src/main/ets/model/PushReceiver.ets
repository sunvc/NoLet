import { UIAbility } from '@kit.AbilityKit';
import { pushService, pushCommon } from '@kit.PushKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { messageStore } from './DBTools';
import { parsePush } from './PushParser';
import { MessagesState } from './MessagesState';
import { postMessageNotification } from './Notify';
import { playRawSound } from '../tools/RawSoundPlayer';
import { applyPushCopy } from '../tools/PushClipboard';
import { defaultGroup } from '../tools/I18n';
import { Haptics } from '../tools/Haptics';

const DOMAIN = 0x0000;
const TAG = 'PushReceiver';

// 应用是否在前台：BACKGROUND 数据消息仅在应用处于后台时补发本地通知，
// 前台收到直接入库刷新 UI 即可（通知栏不弹）。
// 由 EntryAbility 的前后台回调设置（同一进程内共享）。
let appForeground: boolean = false;

export function setPushReceiverForeground(foreground: boolean): void {
  appForeground = foreground;
}

// 注册推送消息接收。必须在 PushMessageAbility.onCreate 中同步调用，
// 不能放在任何 await 之后，否则 Ability 被推送拉起当次的消息会错过注册。
// 接收方 Ability 必须在 module.json5 声明 action.ohos.push.listener skill。
//
// - DEFAULT：通知消息，仅 App 在前台时走此回调（后台/被杀由 RemoteNotificationExtAbility 处理）
// - BACKGROUND：数据消息，不展示通知，后台时由我们补发本地通知
// - IM：语音播报消息，入库并播放 rawfile 自定义铃声
// （VoIP 需要通话业务和系统能力，当前不注册）
export function registerPushReceiver(ability: UIAbility): void {
  registerOne(ability, 'DEFAULT', handleDefaultOrBackground);
  registerOne(ability, 'BACKGROUND', handleDefaultOrBackground);
  registerOne(ability, 'IM', handleIm);
}

type PayloadHandler = (ability: UIAbility, type: string, data: pushCommon.PushPayload) => Promise<void>;

function registerOne(
  ability: UIAbility,
  type: pushService.PushType,
  handler: PayloadHandler
): void {
  try {
    pushService.receiveMessage(type, ability, (data: pushCommon.PushPayload) => {
      Haptics.success()
      handler(ability, type, data).catch((e: Error): void => {
        hilog.error(DOMAIN, TAG, `handle ${type} failed: ${e.message}`);
      });
    });

    hilog.info(DOMAIN, TAG, `receiveMessage ${type} registered`);
  } catch (err) {
    const e = err as BusinessError;
    hilog.error(DOMAIN, TAG, `receiveMessage ${type} failed: ${e.code} ${e.message}`);
  }
}

// DEFAULT / BACKGROUND：解析 → 入库（或删除）→ 刷新 UI；
// BACKGROUND 且应用在后台时补发本地通知。
async function handleDefaultOrBackground(
  ability: UIAbility,
  type: string,
  data: pushCommon.PushPayload
): Promise<void> {
  hilog.info(DOMAIN, TAG, `receive ${type}: ${data.data}`);
  // init 内部有 readyPromise 幂等保护，可与 EntryAbility 中的初始化并发调用
  await messageStore.init(ability.context);

  const result = parsePush(data.data, defaultGroup(ability.context));
  if (!result) return;

  if (result.action === 'delete') {
    await messageStore.delete(result.message.id);
  } else {
    await messageStore.upsert(result.message);
    // copy 参数：前台路径同样写入系统剪贴板（后台/被杀由推送扩展处理）
    applyPushCopy(result.copy, result.message);
    // 数据消息本身不展示，应用在后台时由本地通知弹出
    if (type === 'BACKGROUND' && !appForeground) {
      await postMessageNotification(ability.context, result.message);
    }
  }
  await MessagesState.instance?.refresh();
}

// IM 语音播报：解析 → 入库 → 播放自定义铃声。
// IM 类型系统自身会展示通知，这里不再补发本地通知。
async function handleIm(
  ability: UIAbility,
  _type: string,
  data: pushCommon.PushPayload
): Promise<void> {
  hilog.info(DOMAIN, TAG, `receive IM: ${data.data}`);
  await messageStore.init(ability.context);

  const result = parsePush(data.data, defaultGroup(ability.context));
  if (!result) return;

  if (result.action === 'delete') {
    await messageStore.delete(result.message.id);
  } else {
    await messageStore.upsert(result.message);
    applyPushCopy(result.copy, result.message);
    await playRawSound(ability.context, result.sound);
  }
  await MessagesState.instance?.refresh();
}
