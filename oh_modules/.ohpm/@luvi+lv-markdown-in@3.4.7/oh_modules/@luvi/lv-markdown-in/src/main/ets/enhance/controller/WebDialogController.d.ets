// @keepTs
// @ts-nocheck
export type WebDialogMode = "url" | "html" | "text";
export declare class WebDialogController {
    private static instance;
    private baseContentNode;
    title: string;
    src: string;
    mode: WebDialogMode;
    javaScriptAccess: boolean;
    /**
     * 打开模态框
     */
    openBindSheet(q63: string, r63: string): Promise<void>;
    openHtmlBindSheet(n63: string, o63: string, p63?: boolean): Promise<void>;
    openTextBindSheet(l63: string, m63: string): Promise<void>;
    private openSheet;
    /**
     * 关闭模态弹窗
     */
    closeBindSheet(): Promise<void>;
    static getInstance(): WebDialogController;
}
