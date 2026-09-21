// @keepTs
// @ts-nocheck
@Builder
export declare function WebDialogBuilder(): void;
@Component
export declare struct WebDialog {
    controller: WebviewController;
    @State
    loading: boolean;
    @State
    webSrc: string;
    aboutToAppear(): void;
    private buildWebSrc;
    private writeHtmlToCache;
    private canLoadWeb;
    build(): void;
}
