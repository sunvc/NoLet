// @keepTs
// @ts-nocheck
import { PluginNode } from './TreeNode';
export type PluginDisplay = 'inline' | 'block';
export type PluginMatchMode = 'inline-prefix' | 'full-line';
export type PluginRenderer = WrappedBuilder<[
    PluginNode
]>;
export interface InlinePluginLayout {
    width: number;
    height: number;
}
export type PluginInlineLayoutResolver = (node: PluginNode) => InlinePluginLayout;
export interface MarkdownPlugin {
    key: string;
    display: PluginDisplay;
    pattern: string;
    flags?: string;
    matchMode: PluginMatchMode;
    selectable?: boolean;
    inlineLayout?: PluginInlineLayoutResolver;
    render: PluginRenderer;
}
export interface PluginSyntaxManifest {
    key: string;
    display: PluginDisplay;
    pattern: string;
    flags?: string;
    matchMode: PluginMatchMode;
    selectable?: boolean;
}
export declare function toPluginSyntaxManifestList(r91: MarkdownPlugin[] | undefined): PluginSyntaxManifest[];
