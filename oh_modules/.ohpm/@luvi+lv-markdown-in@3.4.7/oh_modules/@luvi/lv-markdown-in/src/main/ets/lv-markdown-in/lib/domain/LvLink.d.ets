// @keepTs
// @ts-nocheck
@Observed
declare class LvLink {
    private textSize;
    private textColor;
    private textUnderline;
    private linkUrl;
    setTextSize(z125: number | string): void;
    setTextColor(y125: string): void;
    setTextUnderline(x125: boolean): void;
    setLinkUrl(w125: string): void;
    getTextSize(): number | string;
    getTextColor(): string;
    getTextUnderline(): boolean;
    getLinkUrl(): string;
}
declare const lvLink: LvLink;
export { lvLink, LvLink };
