import { common } from '@kit.AbilityKit';
import { media } from '@kit.MediaKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { hdsTitleBar } from '../components/HdsTitle';
import { NavList, TITLE_BAR_HEIGHT_MINI } from '../components/NavList';
import { HdsListItemCard, HdsNavDestination, SuffixCustomBuilder } from '@kit.UIDesignKit';

const DOMAIN = 0x0000;
const TAG = 'SoundSettings';

// 对应 iOS SoundView：rawfile 内自带铃声。点击仅试听（再点停止）。
// 华为通知铃声只能在系统设置里配置，应用内不提供「设为默认」与上传铃声。
@ComponentV2
export struct SoundSettingsView {
  @Local sounds: string[] = [];
  @Local playing: string = '';
  private player: media.AVPlayer | null = null;
  private currentName: string = '';
  // 试听序号：快速连点时只保留最后一次播放的回调生效
  private playSeq: number = 0;
  // prepare 期间忽略连点（getRawFd 返回资源管理器按 hap 缓存的共享 fd，重复播放不能关闭它）
  private busy: boolean = false;
  private scroller: ListScroller = new ListScroller();

  aboutToAppear(): void {
    this.loadSounds();
  }

  aboutToDisappear(): void {
    this.playSeq++;
    this.player?.release();
    this.player = null;
  }

  async loadSounds(): Promise<void> {
    try {
      const context = this.getUIContext().getHostContext() as common.Context;
      const files = await context.resourceManager.getRawFileList('');
      this.sounds = files
        .filter(f => f.endsWith('.mp3'))
        .map(f => f.slice(0, -4))
        .sort();
    } catch (e) {
      hilog.error(DOMAIN, TAG, `loadSounds failed: ${(e as Error).message}`);
    }
  }

  // rawfile 描述符直连播放。AVPlayer 状态切换全部异步，必须在 stateChange 回调里逐级驱动：
  // idle →(fdSrc) initialized →(prepare) prepared →(play) playing → completed。
  // 不能在赋 fdSrc 后同步调 prepare（此时仍是 idle，会报 401）。
  // getRawFd 的 fd 归资源管理器/播放器管理，应用侧不要 close。
  async play(name: string): Promise<void> {
    if (this.busy) return;
    this.busy = true;
    const seq: number = ++this.playSeq;
    try {
      const oldPlayer: media.AVPlayer | null = this.player;
      this.player = null;
      if (oldPlayer) {
        await oldPlayer.release();
      }

      const context = this.getUIContext().getHostContext() as common.Context;
      const desc = await context.resourceManager.getRawFd(`${name}.mp3`);

      const player: media.AVPlayer = await media.createAVPlayer();
      player.on('stateChange', (state: string): void => {
        if (seq !== this.playSeq) return;
        if (state === 'initialized') {
          player.prepare();
        } else if (state === 'prepared') {
          player.play();
          this.busy = false;
        } else if (state === 'playing') {
          this.playing = name;
        } else if (state === 'completed' || state === 'stopped') {
          this.playing = '';
        }
      });
      player.on('error', (err: BusinessError): void => {
        hilog.error(DOMAIN, TAG, `player error: ${err.code} ${err.message}`);
        if (seq === this.playSeq) this.playing = '';
        this.busy = false;
      });
      // 触发 idle → initialized（异步），随后由 stateChange 回调自动 prepare/play
      player.fdSrc = { fd: desc.fd, offset: desc.offset, length: desc.length };
      this.player = player;
      this.currentName = name;
    } catch (e) {
      hilog.error(DOMAIN, TAG, `play ${name} failed: ${(e as Error).message}`);
      this.busy = false;
    }
  }

  stop(): void {
    this.playing = '';
    this.player?.stop();
  }

  // 试听：正在播放同一首时再点停止
  audition(name: string): void {
    if (this.playing === name) {
      this.stop();
    } else {
      this.play(name);
    }
  }

  // 右侧尾部：播放状态指示（试听由整卡点击承担，不处理点击）
  @Builder
  trailing(name: string) {
    SymbolGlyph(this.playing === name
      ? $r('sys.symbol.speaker_wave_2_fill')
      : $r('sys.symbol.speaker_wave_2'))
      .fontSize(20)
      .fontColor([this.playing === name ? '#1698CE' : $r('app.color.text_tertiary')])
      .margin({ right: 4 })
  }

  build() {
    HdsNavDestination() {
      // HDS 卡片自带 16vp 外边距，hPadding 设 0 避免双倍缩进
      NavList({ space: 8, hPadding: 0, titleHeight: TITLE_BAR_HEIGHT_MINI, topGap: 0,
        scroller: this.scroller }) {
        ForEach(this.sounds, (name: string) => {
          ListItem() {
            HdsListItemCard({
              textItem: { primaryText: { text: name } },
              suffixItem: new SuffixCustomBuilder((): void => { this.trailing(name); }),
              cardBackgroundColor: $r('app.color.bg_card'),
              onClick: (): void => this.audition(name)
            })
          }
        }, (name: string) => name)
        ListItem() {
          Text($r('app.string.tap_to_preview'))
            .fontSize(13)
            .fontColor($r('app.color.text_tertiary'))
            .width('100%')
            .textAlign(TextAlign.Center)
            .padding({ top: 6, bottom: 8 })
        }
      }
    }
    .titleBar(hdsTitleBar($r('app.string.title_sound')))
    .bindToScrollable([this.scroller])
    .ignoreLayoutSafeArea([LayoutSafeAreaType.SYSTEM],
      [LayoutSafeAreaEdge.TOP, LayoutSafeAreaEdge.BOTTOM])
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    .backgroundColor($r('app.color.bg_page'))
  }
}
