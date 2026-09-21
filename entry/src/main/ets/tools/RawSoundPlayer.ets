import { media } from '@kit.MediaKit';
import { common } from '@kit.AbilityKit';
import { resourceManager } from '@kit.LocalizationKit';

// RemoteNotificationExtAbility 子进程内播放 rawfile 自定义铃声。
// 扩展生命周期不足 10 秒，播放完成或超时后释放资源，Promise 始终 resolve（找不到文件静默跳过）。
const MAX_PLAY_MS = 8000;

export async function playRawSound(context: common.Context, sound: string): Promise<void> {
  const name = (sound ?? '').trim();
  // 空值 / default：不叠加自定义音，交给系统通知默认提示音
  if (!name || name.toLowerCase() === 'default') return;
  const file = name.toLowerCase().endsWith('.mp3') ? name : `${name}.mp3`;

  let descriptor: resourceManager.RawFileDescriptor;
  try {
    descriptor = await context.resourceManager.getRawFd(file);
  } catch {
    // rawfile 中没有对应铃声：静默
    return;
  }

  const player: media.AVPlayer = await media.createAVPlayer();
  await new Promise<void>((resolve: () => void): void => {
    let done = false;
    const finish = (): void => {
      if (done) return;
      done = true;
      clearTimeout(timer);
      try {
        context.resourceManager.closeRawFd(file);
      } catch {
        // fd 随扩展进程结束也会释放
      }
      player.release()
        .then((): void => resolve())
        .catch((): void => resolve());
    };
    // 兜底：无论音频多长，8 秒内必须收尾，避免超出扩展 10 秒生命周期
    const timer = setTimeout(finish, MAX_PLAY_MS);
    player.on('stateChange', (state: string): void => {
      if (state === 'initialized') {
        // fdSrc 赋值后 native 异步切到 initialized，必须在回调里 prepare；
        // 赋值后同步调用会因仍是 idle 被拒，之后永远到不了 prepared，只能耗到 8 秒超时
        player.prepare().catch((): void => finish());
      } else if (state === 'prepared') {
        player.play();
      } else if (state === 'completed' || state === 'error' || state === 'released') {
        finish();
      }
    });
    player.on('error', (): void => finish());
    player.fdSrc = { fd: descriptor.fd, offset: descriptor.offset, length: descriptor.length };
  });
}
