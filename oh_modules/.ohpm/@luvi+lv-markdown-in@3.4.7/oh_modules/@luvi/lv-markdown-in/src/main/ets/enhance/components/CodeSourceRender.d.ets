// @keepTs
// @ts-nocheck
import { HighlightNode } from '../model/highlightNode';
@Component
export declare struct CodeSourceRender {
    @Prop
    markdownUnion: string;
    @Prop
    text: string;
    @Prop
    lang: string;
    @Prop
    autoCollapse: boolean;
    @Prop
    selectable: boolean;
    @Prop
    lineNumberWidth: number;
    @Prop
    contentBottomPadding: number;
    @Prop
    contentTopPadding: number;
    @Prop
    selectionUnion: string;
    @Prop
    textSelectionEnabled: boolean;
    @State
    highlightNode: HighlightNode[];
    @State
    MAX_ROWS: number;
    BASE_ROWS: number;
    private highlightVersion;
    private highlightDebounceTimer;
    private lastContributedCacheKey;
    private codeThemeListener;
    private textController;
    private selectionId;
    private selectionMouseTracker;
    aboutToAppear(): void;
    aboutToDisappear(): void;
    refreshHighlight(): void;
    private shouldAutoCollapse;
    private applyHighlightRows;
    private buildPlainTextRows;
    private visibleRows;
    private visibleRowCount;
    private showMore;
    private getVisibleCodeText;
    private syncSelectionBlock;
    private unregisterSelectionBlock;
    private invalidateSelectionLayout;
    private isDarkTheme;
    private showLineNumber;
    private RenderCodeText;
    build(): void;
}
