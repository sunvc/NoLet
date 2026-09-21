// @keepTs
// @ts-nocheck
export declare class CodeDialogController {
    private static instance;
    private baseContentNode;
    markdownUnion: string;
    lang: string;
    text: string;
    openBindSheet(v54: string, w54: string, x54: string): Promise<void>;
    closeBindSheet(): Promise<void>;
    static getInstance(): CodeDialogController;
}
