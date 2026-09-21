// @keepTs
// @ts-nocheck
import { CodeBlockNode } from '../model/TreeNode';
type HtmlTab = "preview" | "code";
@Component
export declare struct HtmlRender {
    @Consume
    markdownUnion: string;
    @Prop
    base: CodeBlockNode | undefined;
    @Prop
    streamingActive: boolean;
    @State
    activeTab: HtmlTab;
    @State
    previewSrc: string;
    @State
    previewError: string;
    @State
    loading: boolean;
    @State
    previewLoading: boolean;
    @State
    poolRenderVersion: number;
    controller: WebviewController;
    private previewFilePath;
    private previewSignature;
    private componentAlive;
    private previewVisible;
    private poolOwnerKey;
    private poolSlot;
    private poolRequestedSrc;
    private slotRetryTimer;
    aboutToAppear(): void;
    aboutToDisappear(): void;
    private deletePreviewFile;
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
    private buildPreviewSignature;
    private handleBaseChange;
    handleStreamingChange(): void;
    private isPreviewSuppressed;
    private writeHtmlToCache;
    private openCodeDialog;
    private openPreview;
    private openActiveFullscreen;
    build(): void;
}
export {};
