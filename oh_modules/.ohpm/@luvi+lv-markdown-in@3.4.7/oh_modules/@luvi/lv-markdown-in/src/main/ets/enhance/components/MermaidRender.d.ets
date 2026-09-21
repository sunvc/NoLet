// @keepTs
// @ts-nocheck
import { CodeBlockNode } from '../model/TreeNode';
type MermaidTab = "preview" | "code";
@Component
export declare struct MermaidRender {
    @Consume
    markdownUnion: string;
    @Prop
    base: CodeBlockNode | undefined;
    @Prop
    streamingActive: boolean;
    @State
    loading: boolean;
    @State
    activeTab: MermaidTab;
    private previewLoading;
    @State
    previewSrc: string;
    @State
    previewError: string;
    @State
    themeVersion: number;
    @State
    poolRenderVersion: number;
    controller: WebviewController;
    private previewFilePath;
    private previewQueued;
    private componentAlive;
    private previewVisible;
    private previewVersion;
    private slotRetryTimer;
    private previewSignature;
    private poolOwnerKey;
    private poolSlot;
    private poolRequestedSrc;
    private mermaidThemeListener;
    aboutToAppear(): void;
    aboutToDisappear(): void;
    private deletePreviewFile;
    private mermaidThemeChangeListener;
    private buildPreviewSignature;
    private handleBaseChange;
    handleStreamingChange(): void;
    private isPreviewSuppressed;
    private getRenderTheme;
    private getCodeBlockTheme;
    private isDarkTheme;
    private getActiveTabBackgroundColor;
    private getTabTextColor;
    private getLoadingColor;
    private getLanguageLabel;
    private getCodeTabWidth;
    private shouldUseWebPreviewPool;
    private preloadWebPreviewPool;
    private releasePooledPreview;
    private clearSlotAcquireRetry;
    private scheduleSlotAcquireRetry;
    private acquirePooledPreview;
    private resolveMermaidTheme;
    private enqueueInlinePreview;
    private loadInlinePreview;
    private writeHtmlToCache;
    private openCodeDialog;
    private openPreview;
    private openActiveFullscreen;
    build(): void;
}
export {};
