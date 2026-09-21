import { pasteboard } from '@kit.BasicServicesKit';
import { common, abilityAccessCtrl } from '@kit.AbilityKit';
import { UIContext, promptAction } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { appStore } from '../store/AppStore';
import { ServerInfo } from '../model/ServerInfo';
import { sendQuickPush, buildQuickSendOptions } from './QuickSender';
import { shareLanText, LanShareResult } from './LanShare';
import { resByName } from './I18n';

const DOMAIN = 0x0000;
const TAG = 'QuickClipboard';

// 进程内去重：同一段剪贴板内容不会在每次回前台时重复触发
let lastHandled: string = '';
// 进程内检测锁：同一次启动/回前台可能有多个触发点（onForeground + loadContent），只执行一次
let checkInFlight: boolean = false;

// 进入应用时检测剪贴板：
// - lanShare：加密 UDP 广播给同一 Wi-Fi 下的电脑
// - autoSend：有默认快捷服务器时直接发送
// - quickSend：弹窗由用户确认后发送
export async function checkClipboardQuickSend(uiContext: UIContext | null, context: common.Context): Promise<void> {
  if (checkInFlight) return;
  checkInFlight = true;
  try {
    const state = appStore.getState();
    hilog.info(DOMAIN, TAG,
      `check: autoSend=${state.autoSend} quickSend=${state.quickSend} lanShare=${state.lanShare} ` +
      `quickServers=${state.quickServers.length}`);
    if (!state.autoSend && !state.quickSend && !state.lanShare) return;
    // 未授予剪贴板权限时静默跳过（开启开关时会申请；系统设置里也可撤销）
    const aac = abilityAccessCtrl.createAtManager();
    const grantStatus = await aac.checkAccessToken(context.applicationInfo.accessTokenId,
      'ohos.permission.READ_PASTEBOARD');
    if (grantStatus !== 0) {
      hilog.info(DOMAIN, TAG, 'check: READ_PASTEBOARD not granted, skip');
      return;
    }

    const data = await pasteboard.getSystemPasteboard().getData();
    const text: string = (data.getPrimaryText() ?? '').trim();
    hilog.info(DOMAIN, TAG, `check: clipboard text length=${text.length} last=${lastHandled.length}`);
    if (!text || text === lastHandled) {
      hilog.info(DOMAIN, TAG, 'check: empty or already handled, skip');
      return;
    }
    lastHandled = text;

    // 局域网广播：独立于快捷服务器，失败按原因提示，不阻断后续推送流程
    if (state.lanShare) {
      const lanResult: LanShareResult = await shareLanText(text);
      showToast(uiContext, resByName(context, lanToastKey(lanResult)));
    }

    if (!state.autoSend && !state.quickSend) return;
    const target: ServerInfo | undefined = state.quickServers.find((s: ServerInfo): boolean => s.isDefault);
    if (!target) {
      hilog.info(DOMAIN, TAG, 'check: no default quick server, skip');
      return;
    }

    const title: string = resByName(context, 'quick_notify_title');
    const targetName: string = target.remark || `${target.url}/${target.key}`;

    if (state.autoSend) {
      hilog.info(DOMAIN, TAG, `auto send to ${target.url}/${target.key}, ${text.length} chars`);
      const ok: boolean = await sendQuickPush(target, text, buildQuickSendOptions(title));
      showToast(uiContext, resByName(context, ok ? 'quick_sent' : 'quick_send_failed'));
      return;
    }

    // quickSend：弹窗确认
    if (!uiContext) {
      hilog.warn(DOMAIN, TAG, 'quickSend: UIContext null, cannot show dialog');
      return;
    }
    const result: promptAction.ShowDialogSuccessResponse = await uiContext.getPromptAction().showDialog({
      title: resByName(context, 'quick_send_dialog_title'),
      message: resByName(context, 'quick_send_dialog_message', targetName),
      buttons: [
        { text: resByName(context, 'action_cancel'), color: '#8E8E93' },
        { text: resByName(context, 'quick_send'), color: '#1698CE' }
      ]
    });
    if (result.index === 1) {
      const ok: boolean = await sendQuickPush(target, text, buildQuickSendOptions(title));
      showToast(uiContext, resByName(context, ok ? 'quick_sent' : 'quick_send_failed'));
    }
  } catch (e) {
    hilog.error(DOMAIN, TAG, `check failed: ${(e as Error).message}`);
  } finally {
    checkInFlight = false;
  }
}

// 应用进入后台时调用，允许下次回前台重新检测
export function resetQuickClipboardCheck(): void {
  checkInFlight = false;
}

// 局域网广播结果 → 文案 key
function lanToastKey(result: LanShareResult): string {
  if (result.ok) return 'lan_sent';
  if (result.reason === 'no_wifi') return 'lan_no_wifi';
  if (result.reason === 'too_large') return 'lan_too_large';
  return 'lan_send_failed';
}

function showToast(uiContext: UIContext | null, message: string): void {
  if (!uiContext) return;
  uiContext.getPromptAction().showToast({
    message,
    duration: 2000,
    showMode: promptAction.ToastShowMode.DEFAULT,
    bottom: 120
  });
}
