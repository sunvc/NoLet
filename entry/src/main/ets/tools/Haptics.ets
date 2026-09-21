import { vibrator } from '@kit.SensorServiceKit';
import { appStore } from '../store/AppStore';

// 震动反馈统一入口：受「更多设置 - 震动」开关控制，关闭时所有反馈静默
export class Haptics {
  // 操作成功的轻提示震动（复制成功、发送成功、切换 Tab、随机密钥等）
  static success(): void {
    if (!appStore.getState().haptics) {
      return;
    }
    vibrator.startVibration({ type: 'preset', effectId: 'haptic.notice.success', count: 1 },
      { usage: 'notification' }, () => {});
  }

  // 操作未生效的警示震动（如导入重复配置）
  static warning(): void {
    if (!appStore.getState().haptics) {
      return;
    }
    vibrator.startVibration({ type: 'preset', effectId: 'haptic.notice.warning', count: 1 },
      { usage: 'notification' }, () => {});
  }
}
