// @keepTs
// @ts-nocheck
import { InlinePluginLayout } from '../model/MarkdownPlugin';
import { PluginNode } from '../model/TreeNode';
@Component
export declare struct PluginBlockRenderHost {
    @Prop
    node: PluginNode;
    renderer: WrappedBuilder<[
        PluginNode
    ]> | undefined;
    build(): void;
}
@Component
export declare struct PluginInlineRenderHost {
    @Prop
    node: PluginNode;
    renderer: WrappedBuilder<[
        PluginNode
    ]> | undefined;
    build(): void;
}
export declare function getPluginRenderer(n40: string, o40: PluginNode): WrappedBuilder<[
    PluginNode
]> | undefined;
export declare function getPluginInlineLayout(k40: string, l40: PluginNode): InlinePluginLayout | undefined;
export declare function hasPluginInlineOverlay(i40: string, j40: PluginNode): boolean;
export declare function getPluginInlinePlaceholderWidth(g40: string, h40: PluginNode): number;
export declare function getPluginInlinePlaceholderHeight(e40: string, f40: PluginNode): number;
@Builder
export declare function PluginInlinePlaceholderSpan(v39: string, w39: PluginNode): void;
