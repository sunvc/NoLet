import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { registerPushReceiver } from '../model/PushReceiver';

const DOMAIN = 0x0000;
const TAG = 'PushMessageAbility';

// 推送消息接收 Ability（module.json5 中声明 action.ohos.push.listener）。
// 推送到达时由系统拉起本 Ability，onCreate 中同步注册 DEFAULT / BACKGROUND / IM 回调。
// 纯后台用途，不加载任何页面。
export default class PushMessageAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(DOMAIN, TAG, 'onCreate');
    // 必须同步调用，不能放在任何 await 之后
    registerPushReceiver(this);
  }

  onDestroy(): void {
    hilog.info(DOMAIN, TAG, 'onDestroy');
  }
}
