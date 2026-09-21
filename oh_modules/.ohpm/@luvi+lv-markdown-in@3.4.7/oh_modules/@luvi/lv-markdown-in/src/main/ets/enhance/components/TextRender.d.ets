// @keepTs
// @ts-nocheck
import { TreeNode } from '../model/TreeNode';
@Component
export declare struct TextRender {
    @Consume
    markdownUnion: string;
    @Consume
    selectionUnion: string;
    @Consume
    pluginUnion: string;
    @Prop
    base: TreeNode | undefined;
    @State
    private latexRefreshTick;
    @State
    private inlinePluginPlacements;
    @State
    private inlinePluginRects;
    private latexLoadingSet;
    private textController;
    private selectionId;
    private inlinePluginRefreshTimer;
    private selectionMouseTracker;
    aboutToAppear(): void;
    private prepareInlinePluginPlacements;
    private getInlinePluginRectKey;
    private getChildNodeKey;
    private refreshInlinePluginRects;
    private refreshInlinePluginRectsSoon;
    private clearInlinePluginRefreshTimer;
    private handleTextAreaChange;
    private syncSelectionBlock;
    private collectLatexNodes;
    private loadTextLatex;
    private hasLatexNode;
    private getTextLineHeight;
    private RenderInlineContent;
    build(): void;
}
