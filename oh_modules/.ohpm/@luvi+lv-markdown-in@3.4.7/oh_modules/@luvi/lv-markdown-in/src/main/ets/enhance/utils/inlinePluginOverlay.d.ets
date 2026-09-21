// @keepTs
// @ts-nocheck
import common2D from "@ohos.graphics.common2D";
import { InlinePluginLayout } from '../model/MarkdownPlugin';
import { PluginNode, TreeNode } from '../model/TreeNode';
export declare class InlinePluginPlacement {
    node: PluginNode;
    start: number;
    end: number;
    layout: InlinePluginLayout;
    constructor(w113: PluginNode, x113: number, y113: number, z113: InlinePluginLayout);
}
export declare class InlinePluginRect {
    node: PluginNode;
    start: number;
    end: number;
    left: number;
    top: number;
    width: number;
    height: number;
    constructor(u113: InlinePluginPlacement, v113: common2D.Rect);
}
export declare function restoreCachedInlinePluginRects(j113: string, k113: InlinePluginPlacement[]): InlinePluginRect[];
export declare function cacheInlinePluginRects(f113: string, g113: InlinePluginRect[]): void;
export declare function isSameInlinePluginRects(c113: InlinePluginRect[], d113: InlinePluginRect[]): boolean;
export declare function buildParagraphInlinePluginPlacements(u111: string, v111: string, w111: TreeNode | undefined): InlinePluginPlacement[];
export declare function buildTextInlinePluginPlacements(q111: string, r111: string, s111: TreeNode | undefined): InlinePluginPlacement[];
export declare function buildInlinePluginRects(h111: TextController, i111: InlinePluginPlacement[], j111: UIContext): InlinePluginRect[];
