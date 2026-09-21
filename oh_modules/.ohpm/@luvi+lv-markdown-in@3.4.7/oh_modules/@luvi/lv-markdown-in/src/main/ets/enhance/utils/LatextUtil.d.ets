// @keepTs
// @ts-nocheck
import image from "@ohos.multimedia.image";
export interface LatexInfo {
    pixelMap: image.PixelMap;
    width: number;
    height: number;
}
export declare namespace LatexUtil {
    function latexToPixelMap(l114: string, m114: number, n114: number, o114: UIContext): Promise<LatexInfo>;
    function getCachedLatex(i114: string, j114: number, k114: number): LatexInfo | undefined;
    function clearCache(): void;
}
