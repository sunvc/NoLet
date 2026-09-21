// @keepTs
// @ts-nocheck
@Observed
declare class LvImage {
    private imgWidth;
    private imgHeight;
    private confGlobal;
    private imgUrl;
    setImgWidth(v125: string): void;
    setImgHeight(u125: string): void;
    setConfGlobal(t125: boolean): void;
    setImgUrl(s125: string): void;
    getImgWidth(): number | string;
    getImgHeight(): number | string | null;
    getConfGlobal(): boolean;
    getImgUrl(): string;
}
declare const lvImage: LvImage;
export { lvImage, LvImage };
