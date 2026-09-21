import { Message } from '../model/Message';
import { messageStore } from '../model/DBTools';
import { MessageCard } from '../components/MessageCard';
import { MessageReader } from '../components/MessageReader';
import { hdsTitleBar } from '../components/HdsTitle';
import { NavList, TITLE_BAR_HEIGHT_MINI } from '../components/NavList';
import { messageLocator } from '../model/MessageLocator';
import { HdsNavDestination } from '@kit.UIDesignKit';
import { common } from '@kit.AbilityKit';
import { resByName, displayGroup } from '../tools/I18n';

// 对应 iOS MessageDetailView：某分组下的全部消息，进入即标记该分组已读
@ComponentV2
export struct MessageDetailView {
  @Require @Param group: string;
  @Require @Param onChanged: () => Promise<void>;
  @Local list: Message[] = [];
  // 双击/查看更多 整屏阅读：当前消息与遮罩显隐
  @Local detailMsg: Message | null = null;
  @Local showDetail: boolean = false;
  private listScroller: Scroller = new Scroller();

  aboutToAppear(): void {
    this.load();
  }

  // 进入时保留未读（卡片左缘绿条），只加载列表
  async load(): Promise<void> {
    this.list = await messageStore.latest(this.group);
    // 点击推送进入：滚动定位到高亮消息（顶部占位占下标 0，故 +1）
    const hid: string = messageLocator.highlightId;
    if (hid) {
      const i: number = this.list.findIndex((m: Message): boolean => m.id === hid);
      if (i >= 0) {
        setTimeout((): void => {
          this.listScroller.scrollToIndex(i + 1, true, ScrollAlign.CENTER);
        }, 150);
      }
    }
  }

  // 从详情页返回主页（NavDestination 出栈销毁）时把该组置已读，并刷新外层分组蓝点
  aboutToDisappear(): void {
    messageStore.markAllRead(this.group)
      .then((): Promise<void> => this.onChanged());
  }

  async deleteOne(id: string): Promise<void> {
    await messageStore.delete(id);
    this.list = await messageStore.latest(this.group);
    await this.onChanged();
  }

  private s(name: string): string {
    return resByName(this.getUIContext().getHostContext() as common.Context, name);
  }

  // 规范分组 '默认' 按当前语言显示
  private groupName(): string {
    return displayGroup(this.getUIContext().getHostContext() as common.Context, this.group);
  }

  // 「查看更多」：整屏覆盖展示完整内容
  private openDetailCover(m: Message): void {
    this.detailMsg = m;
    this.showDetail = true;
  }

  // 全屏阅读层：与消息首页共用 MessageReader（$$ 支持系统返回手势关闭）
  @Builder
  detailCover() {
    if (this.detailMsg) {
      MessageReader({
        message: this.detailMsg,
        onClose: (): void => {
          this.showDetail = false;
        }
      })
    }
  }

  @Builder
  deleteButton(id: string) {
    Button($r('app.string.action_delete'))
      .backgroundColor(Color.Red)
      .fontColor(Color.White)
      .padding({ left: 20, right: 20, top: 8, bottom: 8 })
      .margin({ left: 10 })
      .onClick(() => this.deleteOne(id))
  }

  build() {
    HdsNavDestination() {
      if (this.list.length === 0) {
        Column() {
          Text(this.s('empty_messages'))
            .fontSize(16)
            .fontColor($r('app.color.text_secondary'))
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
      } else {
        NavList({ space: 10, hPadding: 10, titleHeight: TITLE_BAR_HEIGHT_MINI, topGap: 0,
          scroller: this.listScroller }) {
          ForEach(this.list, (item: Message) => {
            ListItem() {
              MessageCard({
                message: item,
                onViewMore: (): void => this.openDetailCover(item)
              })
            }
            .swipeAction({ end: this.deleteButton(item.id) })
          }, (item: Message) => item.id)
        }
      }
    }
    .titleBar(hdsTitleBar(this.groupName()))
    .bindContentCover($$this.showDetail, this.detailCover)
    .bindToScrollable([this.listScroller])
    .ignoreLayoutSafeArea([LayoutSafeAreaType.SYSTEM],
      [LayoutSafeAreaEdge.TOP, LayoutSafeAreaEdge.BOTTOM])
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    .backgroundColor($r('app.color.bg_page'))
  }
}
