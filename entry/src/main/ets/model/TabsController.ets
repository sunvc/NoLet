import { HdsTabsController } from '@kit.UIDesignKit';

// 模块级 HdsTabs 控制器单例：Index 用它驱动悬浮页签，三个 Tab 子页面
// 在二级页入栈/弹输入条时也需用它隐藏与恢复页签栏。
export const tabsController: HdsTabsController = new HdsTabsController();
