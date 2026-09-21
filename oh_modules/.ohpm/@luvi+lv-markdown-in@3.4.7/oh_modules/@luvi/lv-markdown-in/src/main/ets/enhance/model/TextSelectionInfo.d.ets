// @keepTs
// @ts-nocheck
import common2D from "@ohos.graphics.common2D";
import componentUtils from "@ohos.arkui.componentUtils";
export declare class TextSelectionSegment {
    renderedLength: number;
    copyText: string;
    constructor(g93: number, h93: string);
}
export declare class RegisteredTextBlock {
    id: string;
    order: number;
    controller: TextController;
    segments: TextSelectionSegment[];
    renderedLength: number;
    constructor(a93: string, b93: number, c93: TextController, d93: TextSelectionSegment[]);
}
export declare class SelectedTextInfo {
    block: RegisteredTextBlock;
    componentInfo: componentUtils.ComponentInfo;
    rects: common2D.Rect[];
    startIndex: number;
    endIndex: number;
    constructor(v92: RegisteredTextBlock, w92: componentUtils.ComponentInfo, x92: common2D.Rect[], y92: number, z92: number);
    getCaretPosition(q92: componentUtils.ComponentInfo, r92?: boolean): Position | undefined;
}
export declare class BlockHitInfo {
    block: RegisteredTextBlock;
    info: componentUtils.ComponentInfo;
    constructor(o92: RegisteredTextBlock, p92: componentUtils.ComponentInfo);
}
export declare class BlockSelectionStartInfo {
    blockId: string;
    localX: number;
    localY: number;
    showActionBarOnStart: boolean;
    globalX?: number;
    globalY?: number;
    fromBlankArea: boolean;
    constructor(h92: string, i92: number, j92: number, k92?: boolean, l92?: number, m92?: number, n92?: boolean);
}
export declare class CaretInfo {
    blockOrder: number;
    caretIndex: number;
    lessThan(g92: CaretInfo): boolean;
    reset(): void;
}
export declare enum LongPressSelectionType {
    ALL = 0,
    PARAGRAPH = 1,
    CUSTOM = 2
}
/**
 * 长按菜单(复制 / 选取文本)的事件载荷。
 * 由 Markdown 组件在「长按菜单模式」下组装并回调给消费端:
 * - paragraphText: 按压所在文本块(段落)的完整可复制文本, 供「复制」按钮使用。
 * - globalX / globalY: 按压点的窗口坐标(vp), 供消费端把蒙层菜单定位到手指位置。
 * - selectWholeBlock: 组件绑定的「选取文本」动作, 支持全部 / 段落 / 自定义三种选取类型。
 */
export declare class LongPressMenuInfo {
    blockId: string;
    paragraphText: string;
    globalX: number;
    globalY: number;
    selectWholeBlock: (type?: LongPressSelectionType) => void;
    constructor(b92: string, c92: string, d92: number, e92: number, f92: (type?: LongPressSelectionType) => void);
}
export declare class TextSelectionActionContext {
    selectedText: string;
    copy: () => void;
    selectAll: () => void;
    clear: () => void;
    constructor(x91: string, y91: () => void, z91: () => void, a92: () => void);
}
export declare class TextSelectionActionItem {
    title: string;
    fontColor?: ResourceColor;
    onClick: (context: TextSelectionActionContext) => void;
    constructor(u91: string, v91: (context: TextSelectionActionContext) => void, w91?: ResourceColor);
}
