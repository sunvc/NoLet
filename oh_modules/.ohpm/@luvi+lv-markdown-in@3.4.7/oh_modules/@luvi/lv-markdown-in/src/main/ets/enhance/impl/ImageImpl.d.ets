// @keepTs
// @ts-nocheck
import { ImageNode } from '../model/TreeNode';
export declare namespace ImageImpl {
    function handleImageSrc(s70: string, t70?: string): ResourceStr;
    function handleRawfileImage(o70?: string): Resource | "";
    function handleClick(l70: string, m70: string): void;
    function handleImageWidth(j70: string, k70?: ImageNode): number | ResourceStr | null;
    function handleImageMaxWidth(h70: string, i70?: ImageNode): number | ResourceStr | null;
    function handleImageHeight(f70: string, g70?: ImageNode): number | ResourceStr | null;
    function handleImageMaxHeight(d70: string, e70?: ImageNode): number | ResourceStr | null;
    function handleImageBorderRadius(c70: string): number | ResourceStr;
}
