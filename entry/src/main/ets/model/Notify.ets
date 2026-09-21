import { common, wantAgent } from '@kit.AbilityKit';
import { notificationManager } from '@kit.NotificationKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { Message } from './Message';

const DOMAIN = 0x0000;
const TAG = 'Notify';

function hashId(id: string): number {
  let hash = 0;
  for (let i = 0; i < id.length; i++) {
    hash = (hash * 31 + id.charCodeAt(i)) | 0;
  }
  return Math.abs(hash);
}

// BACKGROUND 数据消息不自动展示，由本地通知弹出；点击拉起 EntryAbility
export async function postMessageNotification(
  context: common.UIAbilityContext,
  msg: Message
): Promise<void> {
  try {
    const info: wantAgent.WantAgentInfo = {
      wants: [{
        bundleName: context.abilityInfo.bundleName,
        abilityName: 'EntryAbility',
        parameters: { id: msg.id, group: msg.group, url: msg.url },
      }],
      requestCode: 0,
      operationType: wantAgent.OperationType.START_ABILITY,
      wantAgentFlags: [wantAgent.WantAgentFlags.UPDATE_PRESENT_FLAG],
    };
    const agent = await wantAgent.getWantAgent(info);

    const request: notificationManager.NotificationRequest = {
      id: hashId(msg.id),
      content: {
        notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
        normal: {
          title: msg.title || msg.group,
          text: msg.body,
        },
      },
      wantAgent: agent,
    };
    await notificationManager.publish(request);
  } catch (e) {
    hilog.error(DOMAIN, TAG, `publish failed: ${(e as Error).message}`);
  }
}
