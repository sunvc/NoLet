// @keepTs
// @ts-nocheck
import { CodeTheme } from '../constant/CodeTheme';
import { CodeHighlight } from '../model/CodeHighlight';
import { LongPressMenuInfo, TextSelectionActionItem } from '../model/TextSelectionInfo';
import { MermaidSecurityLevel } from '../utils/MermaidHtmlBuilder';
import componentUtils from "@ohos.arkui.componentUtils";
import drawing from "@ohos.graphics.drawing";
import image from "@ohos.multimedia.image";
/**
 * @description Markdown 组件的控制器，可以将此对象绑定至 Markdown 组件，然后通过它控制 Markdown 组件的自定义样式。同一个控制器可以控制多个 Markdown 组件，多个 API 支持链式调用语法。
 */
@ObservedV2
export declare class MarkdownController {
    private union;
    private titleColor;
    private titleSize;
    private titleLineHeight;
    private titleFontWeight;
    private titleFontStyle;
    private titleFontFamily;
    private textColor;
    private textLineHeight;
    private textSize;
    private textFontFamily;
    private inlineCodeColor;
    private inlineCodeBackgroundColor;
    private inlineCodeBackgroundRadius;
    private quoteTextColor;
    private quoteBorderColor;
    private quoteBorderWidth;
    private quoteBackgroundColor;
    private quoteBorderRadius;
    private quotePadding;
    private codeBlockTheme;
    private codeBlockIdxState;
    private codeBlockBorderRadius;
    private codeBlockAutoCollapseEnable;
    private codeBlockAutoCollapseThreshold;
    private codeBlockActionAreaVisible;
    private codeHighlight;
    private codeCopyListener;
    private imageWidth;
    private imageMaxWidth;
    private imageHeight;
    private imageMaxHeight;
    private imageBorderRadius;
    private imageClickListener;
    private imageLoadProxy;
    private hyperlinkTextColor;
    private hyperlinkTextSize;
    private hyperlinkUnderlineState;
    private hyperlinkBackgroundColor;
    private hyperlinkBackgroundRadius;
    private hyperlinkClickListener;
    private tableBackgroundColor;
    private tableTitleBackgroundColor;
    private tableTitleTextColor;
    private tableInterleaveTextColor;
    private tableNormalTextColor;
    private tableInterleaveBackgroundColor;
    private tableActionBackgroundColor;
    private tableActionIconColor;
    private tableActionIconColorFilter;
    private tableBorderRadius;
    private tableOuterBorderColor;
    private tableOuterBorderWidth;
    private tableInnerBorderColor;
    private tableInnerBorderWidth;
    private tableAlign;
    private tableCopyClickListener;
    private tableDownloadClickListener;
    private tableExpandClickListener;
    private todoSelectedColor;
    private todoSelectSize;
    private ulPointSize;
    private ulPointColor;
    private footnoteTextColor;
    private lineColor;
    private latexMathTextSize;
    private latexMathTextColor;
    private latexClickListener;
    private mermaidEnable;
    private mermaidTheme;
    private mermaidSecurityLevel;
    private htmlPreviewEnable;
    private htmlPreviewJavaScriptEnable;
    private webPreviewPoolEnable;
    private webPreviewPoolInitialSize;
    private webPreviewPoolMaxSize;
    private webPreviewPoolIdleRetain;
    private setextHeadingEnable;
    private threadRenderEnable;
    private lazyRender;
    private lazyPreloadBlockCount;
    private copyOption;
    private textSelectionEnable;
    private textSelectionCopyListener;
    private textSelectionActionItems;
    private textSelectionClearHandlers;
    private longPressMenuEnable;
    private longPressMenuListener;
    private blockSpacing;
    constructor();
    getUnion(): string;
    /**
     * 设置标题-颜色
     * @param color
     * @version 3.2.2
     */
    setTitleColor(w58: ResourceColor | [
        ResourceColor,
        ResourceColor,
        ResourceColor,
        ResourceColor,
        ResourceColor,
        ResourceColor
    ]): this;
    getTitleColor(): ResourceColor | [
        ResourceColor,
        ResourceColor,
        ResourceColor,
        ResourceColor,
        ResourceColor,
        ResourceColor
    ];
    /**
     * 设置标题-字号（1-6级）
     * @param titleSize
     */
    setTitleSize(v58: [
        ResourceStr | number,
        ResourceStr | number,
        ResourceStr | number,
        ResourceStr | number,
        ResourceStr | number,
        ResourceStr | number
    ]): this;
    getTitleSize(): [
        ResourceStr | number,
        ResourceStr | number,
        ResourceStr | number,
        ResourceStr | number,
        ResourceStr | number,
        ResourceStr | number
    ];
    /**
     * 设置标题-行高（1-6级）
     * @param lineHeights
     */
    setTitleLineHeight(u58: [
        ResourceStr | number,
        ResourceStr | number,
        ResourceStr | number,
        ResourceStr | number,
        ResourceStr | number,
        ResourceStr | number
    ]): this;
    getTitleLineHeight(): [
        ResourceStr | number,
        ResourceStr | number,
        ResourceStr | number,
        ResourceStr | number,
        ResourceStr | number,
        ResourceStr | number
    ];
    /**
     * 设置标题-字体粗细
     * @param fontWeight
     * @version 3.2.2
     */
    setTitleFontWeight(t58: FontWeight | [
        FontWeight,
        FontWeight,
        FontWeight,
        FontWeight,
        FontWeight,
        FontWeight
    ]): this;
    getTitleFontWeight(): FontWeight | [
        FontWeight,
        FontWeight,
        FontWeight,
        FontWeight,
        FontWeight,
        FontWeight
    ];
    /**
     * 设置标题-字体样式
     * @param fontStyle
     * @version 3.2.2
     */
    setTitleFontStyle(s58: FontStyle | [
        FontStyle,
        FontStyle,
        FontStyle,
        FontStyle,
        FontStyle,
        FontStyle
    ]): this;
    getTitleFontStyle(): FontStyle | [
        FontStyle,
        FontStyle,
        FontStyle,
        FontStyle,
        FontStyle,
        FontStyle
    ];
    /**
     * 设置标题-字体族（自定义字体）
     * @description 支持给指定级别的标题设置自定义字体。设置数组格式则为指定级别的标题设置自定义字体，设置唯一自定义字体，则1-6级标题全部生效。
     * @param fontFamily
     * @version 3.2.4
     */
    setTitleFontFamily(r58: ResourceStr | [
        ResourceStr,
        ResourceStr,
        ResourceStr,
        ResourceStr,
        ResourceStr,
        ResourceStr
    ]): this;
    getTitleFontFamily(): ResourceStr | [
        ResourceStr,
        ResourceStr,
        ResourceStr,
        ResourceStr,
        ResourceStr,
        ResourceStr
    ];
    /**
     * 设置普通文本-颜色
     * @param textColor
     */
    setTextColor(q58: ResourceColor): this;
    getTextColor(): ResourceColor;
    /**
     * 设置普通文本-行高
     * @param textLineHeight
     */
    setTextLineHeight(p58: ResourceStr | number): this;
    getTextLineHeight(): number | ResourceStr;
    /**
     * 设置普通文本-字号
     * @param textSize
     */
    setTextSize(o58: ResourceStr | number): this;
    getTextSize(): number | ResourceStr;
    /**
     * 设置普通文本-字体族（自定义字体）
     * @param textSize
     */
    setTextFontFamily(n58: ResourceStr): this;
    getTextFontFamily(): ResourceStr;
    /**
     * 设置行内代码-颜色
     * @param inlineCodeColor
     */
    setInlineCodeColor(m58: ResourceColor): this;
    getInlineCodeColor(): ResourceColor;
    /**
     * 设置行内代码-背景颜色
     * @param inlineCodeBackgroundColor
     */
    setInlineCodeBackgroundColor(l58: ResourceColor): this;
    getInlineCodeBackgroundColor(): ResourceColor;
    /**
     * 设置行内代码-背景圆角
     * @param inlineCodeBackgroundRadius
     */
    setInlineCodeBackgroundRadius(k58: Dimension): this;
    getInlineCodeBackgroundRadius(): Dimension;
    /**
     * 设置引用块-文本颜色
     * @param color
     * @returns
     */
    setQuoteTextColor(j58: ResourceColor): this;
    getQuoteTextColor(): ResourceColor;
    /**
     * 设置引用块-左边颜色
     * @param quoteBorderColor
     * @returns
     */
    setQuoteBorderColor(i58: ResourceColor): this;
    getQuoteBorderColor(): ResourceColor;
    /**
     * 设置引用块-背景颜色
     * @param quoteBackgroundColor
     */
    setQuoteBackgroundColor(h58: ResourceColor): this;
    getQuoteBackgroundColor(): ResourceColor;
    /**
     * 设置引用块-圆角
     * @param radius
     * @version 3.2.2
     */
    setQuoteBorderRadius(g58: ResourceStr | number): this;
    getQuoteBorderRadius(): number | ResourceStr;
    /**
     * 设置引用块-左边宽度
     * @param size
     * @version 3.2.2
     */
    setQuoteBorderWidth(f58: ResourceStr | number): this;
    getQuoteBorderWidth(): number | ResourceStr;
    /**
     * 设置引用块-内边距
     * @param radius
     * @version 3.3.0
     */
    setQuotePadding(e58: Padding | Length | LocalizedPadding): this;
    getQuotePadding(): Length | Padding | LocalizedPadding;
    /**
     * 设置代码块-主题
     * @param codeBlockTheme
     */
    setCodeBlockTheme(d58: CodeTheme): this;
    getCodeBlockTheme(): CodeTheme;
    /**
     * 设置代码块-索引展示状态
     * @param codeBlockIdxState
     */
    setCodeBlockIdxState(c58: boolean): this;
    getCodeBlockIdxState(): boolean;
    /**
     * 设置代码块-圆角
     * @param radius
     * @version 3.2.2
     */
    setCodeBlockBorderRadius(b58: number | ResourceStr): this;
    getCodeBlockBorderRadius(): number | ResourceStr;
    /**
     * 设置代码块是否自动折叠
     * @description 默认 false。开启后超过折叠阈值的代码块会折叠并展示展开按钮。
     * @param enable
     */
    setCodeBlockAutoCollapseEnable(a58: boolean): this;
    getCodeBlockAutoCollapseEnable(): boolean;
    /**
     * 设置代码块自动折叠阈值
     * @description 默认 10 行。仅在 setCodeBlockAutoCollapseEnable(true) 后生效。
     * @param threshold
     */
    setCodeBlockAutoCollapseThreshold(z57: number): this;
    getCodeBlockAutoCollapseThreshold(): number;
    /**
     * 设置普通代码块操作区是否展示
     * @description 默认 true。HTML、HTM 和 Mermaid 代码块不受该接口影响。
     * @param visible
     * @version 3.4.6
     */
    setCodeBlockActionAreaVisible(y57: boolean): this;
    getCodeBlockActionAreaVisible(): boolean;
    /**
     * 设置代码高亮着色
     * @param codeHighlight
     */
    setCodeHighlight(x57: CodeHighlight): this;
    getCodeHighlight(): CodeHighlight;
    /**
     * 设置代码块-点击复制监听
     * @param event
     * @returns
     */
    setCodeCopyListener(w57: (text: string) => void): this;
    getCodeCopyListener(v57: string): void;
    /**
     * 获取图片-宽度
     * @param imageWidth
     */
    setImageWidth(u57: ResourceStr | number | null): this;
    getImageWidth(): number | ResourceStr;
    /**
     * 设置图片-最大宽度
     * @param imageMaxWidth
     */
    setImageMaxWidth(t57: ResourceStr | number | null): this;
    getImageMaxWidth(): number | ResourceStr;
    /**
     * 获取图片-高度
     * @param imageWidth
     */
    setImageHeight(s57: ResourceStr | number | null): this;
    getImageHeight(): number | ResourceStr;
    /**
     * 设置图片-最大高度
     * @param imageMaxWidth
     */
    setImageMaxHeight(r57: ResourceStr | number | null): this;
    getImageMaxHeight(): number | ResourceStr;
    /**
     * 设置图片-圆角
     * @param radius
     * @version 3.2.2
     */
    setImageBorderRadius(q57: ResourceStr | number): this;
    getImageBorderRadius(): number | ResourceStr;
    /**
     * 设置图片-点击监听
     * @param event
     * @returns
     */
    setImageClickListener(p57: (src: string) => boolean): this;
    getImageClickListener(): (src: string) => boolean;
    /**
     * 设置图片加载代理
     * @param event
     * @returns
     */
    setImageLoadProxy(o57: (src: string) => string): this;
    getImageLoadProxy(n57: string): string;
    /**
     * 设置超链接-文字颜色
     * @param hyperlinkTextColor
     */
    setHyperlinkTextColor(m57: ResourceColor): this;
    getHyperlinkTextColor(): ResourceColor;
    /**
     * 设置超链接-文字字号
     * @param size
     * @version 3.2.2
     */
    setHyperlinkTextSize(l57: ResourceStr | number): this;
    getHyperlinkTextSize(): number | ResourceStr;
    /**
     * 设置超链接-背景颜色
     * @param inlineCodeBackgroundColor
     */
    setHyperlinkBackgroundColor(k57: ResourceColor): this;
    getHyperlinkBackgroundColor(): ResourceColor;
    /**
     * 设置超链接-背景圆角
     * @param radius
     */
    setHyperlinkBackgroundRadius(j57: Dimension): this;
    getHyperlinkBackgroundRadius(): Dimension;
    /**
     * 设置超链接-下划线展示状态
     * @param hyperlinkUnderlineState
     */
    setHyperlinkUnderlineState(i57: boolean): this;
    getHyperlinkUnderlineState(): boolean;
    /**
     * 设置超链接-点击监听
     * @param event
     * @returns
     */
    setHyperlinkClickListener(h57: (title: string, src: string, anchorInfo?: componentUtils.ComponentInfo) => boolean): this;
    getHyperlinkClickListener(): (title: string, src: string, anchorInfo?: componentUtils.ComponentInfo) => boolean;
    /**
     * 设置表格背景色
     * @param tableBackgroundColor
     */
    setTableBackgroundColor(g57: ResourceColor): this;
    getTableBackgroundColor(): ResourceColor;
    /**
     * 设置表格表头文本颜色
     */
    setTableTitleTextColor(f57: ResourceColor): this;
    getTableTitleTextColor(): ResourceColor;
    /**
     * 设置表格-错行文本颜色
     */
    setTableInterleaveTextColor(e57: ResourceColor): void;
    getTableInterleaveTextColor(): ResourceColor;
    /**
     * 设置表格-非错行文本颜色
     */
    setTableNormalTextColor(d57: ResourceColor): void;
    getTableNormalTextColor(): ResourceColor;
    /**
     * 设置表格-表头背景色
     * @param tableTitleBackgroundColor
     */
    setTableTitleBackgroundColor(c57: ResourceColor): this;
    getTableTitleBackgroundColor(): ResourceColor;
    /**
     * 设置表格-错行背景色
     * @param tableInterleaveBackgroundColor
     */
    setTableInterleaveBackgroundColor(b57: ResourceColor): this;
    getTableInterleaveBackgroundColor(): ResourceColor;
    /**
     * 设置表格-操作区背景色
     * @param tableActionBackgroundColor
     * @version 3.4.6
     */
    setTableActionBackgroundColor(a57: ResourceColor): this;
    getTableActionBackgroundColor(): ResourceColor;
    /**
     * 设置表格-操作图标颜色。仅支持 #RRGGBB、RRGGBB 或空字符串，空字符串恢复图标原始颜色。
     * @param iconColor
     * @version 3.4.6
     */
    setTableActionIconColor(y56: string): this;
    getTableActionIconColor(): string;
    getTableActionIconColorFilter(): drawing.ColorFilter;
    /**
     * 设置表格-圆角
     * @param radius
     * @version 3.2.2
     */
    setTableBorderRadius(x56: ResourceStr | number): this;
    getTableBorderRadius(): number | ResourceStr;
    /**
     * 设置表格-外边框颜色
     * @param color
     * @version 3.2.2
     */
    setTableOuterBorderColor(w56: ResourceColor): this;
    getTableOuterBorderColor(): ResourceColor;
    /**
     * 设置表格-外边框宽度
     * @param width
     * @version 3.2.2
     */
    setTableOuterBorderWidth(v56: ResourceStr | number): this;
    getTableOuterBorderWidth(): number | ResourceStr;
    /**
     * 设置表格-内边框颜色
     * @param color
     * @version 3.2.2
     */
    setTableInnerBorderColor(u56: ResourceColor): this;
    getTableInnerBorderColor(): ResourceColor;
    /**
     * 设置表格-内边框宽度
     * @param width
     * @version 3.2.2
     */
    setTableInnerBorderWidth(t56: ResourceStr | number): this;
    getTableInnerBorderWidth(): number | ResourceStr;
    /**
     * 设置表格-屏幕对齐方式
     * @param flexAlign 对齐方式
     * @version 3.2.2
     */
    setTableAlign(s56: FlexAlign): this;
    getTableAlign(): FlexAlign;
    /**
     * 设置表格-复制点击监听。传入 undefined 时隐藏复制按钮。
     * @version 3.4.6
     */
    setTableCopyClickListener(r56?: (rawTableMarkdown: string) => void): this;
    getTableCopyClickListener(): (rawTableMarkdown: string) => void;
    /**
     * 设置表格-下载点击监听。传入 undefined 时隐藏下载按钮。
     * @version 3.4.6
     */
    setTableDownloadClickListener(q56?: (rawTableMarkdown: string) => void): this;
    getTableDownloadClickListener(): (rawTableMarkdown: string) => void;
    /**
     * 设置表格-放大点击监听。传入 undefined 时隐藏放大按钮。
     * @version 3.4.6
     */
    setTableExpandClickListener(p56?: (rawTableMarkdown: string) => void): this;
    getTableExpandClickListener(): (rawTableMarkdown: string) => void;
    /**
     * 设置任务列表-选中颜色
     * @param todoSelectedColor
     */
    setTodoSelectedColor(o56: ResourceColor): this;
    getTodoSelectedColor(): ResourceColor;
    /**
     * 设置任务列表-选项大小
     * @param todoSelectSize
     */
    setTodoSelectSize(n56: ResourceStr | number): this;
    getTodoSelectSize(): number | ResourceStr;
    /**
     * 设置无序列表-指示点大小
     * @param size
     * @version 3.2.2
     */
    setUlPointSize(m56: ResourceStr | number): this;
    getUlPointSize(): number | ResourceStr;
    /**
     * 设置无序列表-指示点颜色
     * @param color
     * @version 3.2.2
     */
    setUlPointColor(l56: ResourceColor): this;
    getUlPointColor(): ResourceColor;
    /**
     * 设置脚注-文字颜色
     * @param footnoteTextColor
     */
    setFootnoteTextColor(k56: ResourceColor): this;
    getFootnoteTextColor(): ResourceColor;
    /**
     * 设置分割线-颜色
     * @param lineColor
     * @returns
     */
    setLineColor(j56: ResourceColor): this;
    getLineColor(): ResourceColor;
    /**
     * 设置数学公式-字体大小
     * @param size
     * @returns
     */
    setLatexMathTextSize(i56: number): this;
    getLatexMathTextSize(): number;
    /**
     * 数学公式-字体颜色（十六进制）
     * @param color
     * @returns
     */
    setLatexMathTextColor(h56: number): this;
    getLatexMathTextColor(): number;
    /**
     * 设置数学公式-点击监听
     * @param event
     * @returns
     */
    setLatexClickListener(g56: (text: string, pixelMap: image.PixelMap) => boolean): this;
    getLatexClickListener(): (text: string, pixelMap: image.PixelMap) => boolean;
    /**
     * 设置是否开启 mermaid 渲染
     * @param enable
     */
    setMermaidEnable(f56: boolean): this;
    getMermaidEnable(): boolean;
    /**
     * 设置 Mermaid 深浅色主题
     * @param theme
     */
    setMermaidTheme(e56: CodeTheme): this;
    getMermaidTheme(): CodeTheme;
    /**
     * 设置 Mermaid 预览安全级别
     * @param securityLevel
     */
    setMermaidSecurityLevel(d56: MermaidSecurityLevel): this;
    getMermaidSecurityLevel(): MermaidSecurityLevel;
    /**
     * 设置是否开启 HTML 代码块预览
     * @param enable
     */
    setHtmlPreviewEnable(c56: boolean): this;
    getHtmlPreviewEnable(): boolean;
    /**
     * 设置 HTML 代码块预览是否允许执行 JavaScript
     * @description 默认 false。Mermaid 预览不受此开关影响。
     * @param enable
     */
    setHtmlPreviewJavaScriptEnable(b56: boolean): this;
    getHtmlPreviewJavaScriptEnable(): boolean;
    /**
     * 设置 Mermaid/HTML 内联预览是否复用 ArkWeb 预览池
     * @description 默认 false。开启后会预热少量 Web 组件，并在 Mermaid/HTML 预览之间复用。
     * @param enable
     */
    setWebPreviewPoolEnable(a56: boolean): this;
    getWebPreviewPoolEnable(): boolean;
    /**
     * 设置 ArkWeb 预览池大小
     * @description initialSize 为预热数量，maxSize 为最大动态扩容数量，idleRetain 为长期保留的空闲槽数量。
     * @param initialSize
     * @param maxSize
     * @param idleRetain
     */
    setWebPreviewPoolSize(w55: number, x55: number, y55: number): this;
    getWebPreviewPoolInitialSize(): number;
    getWebPreviewPoolMaxSize(): number;
    getWebPreviewPoolIdleRetain(): number;
    /**
     * 设置是否开启线程加载模式（默认开启）
     * @param enable
     */
    setThreadRenderEnable(v55: boolean): this;
    getThreadRenderEnable(): boolean;
    /**
     * 设置是否开启 Setext 标题解析
     * @description 默认 false。开启后，文本下方的 ===== 或 ----- 会解析为一级或二级标题。
     * @param enable
     */
    setSetextHeadingEnable(u55: boolean): this;
    getSetextHeadingEnable(): boolean;
    /**
     * 设置是否开启可见区域懒渲染
     * @description 默认 false。开启后屏幕外块先以轻量占位渲染，进入可见区域附近后再渲染真实内容。
     * @param enable
     */
    setLazyRender(t55: boolean): this;
    getLazyRender(): boolean;
    /**
     * 设置懒渲染预渲染块数量
     * @description 默认 3。实际渲染会按内部懒渲染分组折算。
     * @param count
     */
    setLazyPreloadBlockCount(s55: number): this;
    getLazyPreloadBlockCount(): number;
    /**
     * 设置剪贴板复制范围选项
     * @description 默认 CopyOptions.LocalDevice（支持复制后在所有应用内粘贴）。从 3.3.1 版本开始，该接口不再维护，调用后不再生效，请使用 setTextSelectionEnable() 与 setTextSelectionEnable() 实现文本选择复制功能。
     * @param copyOption
     * @deprecated 3.3.1
     */
    setCopyOption(r55: CopyOptions): void;
    getCopyOption(): CopyOptions;
    /**
     * 设置是否开启跨 Text 文本选择能力
     * @description 默认 false
     * @param enable
     * @version 3.3.2
     */
    setTextSelectionEnable(q55: boolean): this;
    getTextSelectionEnable(): boolean;
    /**
     * 设置跨 Text 文本选择复制监听
     * @param event
     * @version 3.3.2
     */
    setTextSelectionCopyListener(p55: (text: string) => void): this;
    getTextSelectionCopyListener(): (text: string) => void;
    /**
     * 设置跨 Text 文本选择后的操作栏按钮
     * @description 不设置或传空数组时使用默认「复制 / 全选 / 取消」。
     * @param items
     */
    setTextSelectionActionItems(o55: TextSelectionActionItem[]): this;
    getTextSelectionActionItems(): TextSelectionActionItem[];
    /**
     * 清除当前 Controller 绑定 Markdown 实例的文本选区
     * @description 同时清除选区高亮、拖拽手柄和内部操作栏。业务通过 setLongPressMenuListener 创建的弹窗仍需自行关闭。
     * @version 3.4.7
     */
    clearTextSelection(): MarkdownController;
    registerTextSelectionClearHandler(l55: string, m55: () => void): void;
    unregisterTextSelectionClearHandler(k55: string): void;
    /**
     * 设置是否开启长按菜单模式(复制 / 选取文本)
     * @description 默认 false(保持既有「长按立即选区」行为)。开启后需配合 setLongPressMenuListener 实现蒙层菜单。
     *   依赖 setTextSelectionEnable(true)。
     * @param enable
     */
    setLongPressMenuEnable(j55: boolean): this;
    getLongPressMenuEnable(): boolean;
    /**
     * 设置长按菜单事件回调
     * @description 触屏长按时触发, 回调参数携带按压点坐标、所在段落文本与「选取文本」动作。
     * selectWholeBlock 支持全部 / 段落 / 自定义三种选取类型, 无参调用保持自定义起选。
     * @param event
     */
    setLongPressMenuListener(i55: (info: LongPressMenuInfo) => void): this;
    getLongPressMenuListener(): (info: LongPressMenuInfo) => void;
    /**
     * 设置块级元素间距
     * @description 默认 10vp。
     * @param copyOption
     * @version 3.3.0
     */
    setBlockSpacing(h55: number | ResourceStr): void;
    getBlockSpacing(): number | ResourceStr;
}
