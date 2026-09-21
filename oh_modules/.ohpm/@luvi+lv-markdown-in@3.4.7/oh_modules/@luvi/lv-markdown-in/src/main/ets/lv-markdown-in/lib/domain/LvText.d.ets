// @keepTs
// @ts-nocheck
@Observed
declare class LvText {
    private textSize;
    private textColor;
    private textMarkBackground;
    private textLineHeight;
    setTextSize(f126: number | string): void;
    setTextColor(e126: string): void;
    setTextMarkBackground(d126: string): void;
    setTextLineHeight(c126: string): void;
    getTextSize(): number | string;
    getTextColor(): string;
    getTextMarkBackground(): string;
    getTextLineHeight(): string | number;
}
declare const lvText: LvText;
export { lvText, LvText };
