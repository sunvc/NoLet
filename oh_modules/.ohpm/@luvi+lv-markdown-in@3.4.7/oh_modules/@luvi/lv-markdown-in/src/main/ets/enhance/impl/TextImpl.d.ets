// @keepTs
// @ts-nocheck
import { BaseNode, FootnoteRefNode, LinkNode, TextNode, TreeNode } from '../model/TreeNode';
export declare namespace TextImpl {
    function handleFontColor(x73: string, y73: ESObject, z73?: TreeNode | undefined): ResourceColor;
    function handleBackgroundColor(v73: string, w73: ESObject): ResourceColor;
    function handleBackgroundRadius(s73: string, t73: ESObject): Dimension;
    function handleDecoration(q73: string, r73: ESObject): DecorationStyleInterface;
    function handleText(o73: string, p73: TreeNode | TextNode | FootnoteRefNode | LinkNode): string;
    function handleFontWeight(k73: string, l73: ESObject, m73?: TreeNode | undefined): FontWeight | null;
    function handleFontStyle(g73: string, h73: ESObject, i73?: TreeNode | undefined): FontStyle;
    function handleLineHeight(d73: string, e73?: TreeNode): ResourceStr | number;
    function handleFontSize(x72: string, y72?: BaseNode | undefined, z72?: TreeNode | undefined): number | ResourceStr;
    function handleFontFamily(s72: string, t72?: BaseNode | undefined, u72?: TreeNode | undefined): ResourceStr;
    function handleClick(j72: string, k72: ESObject): void;
    function handleSpanId(f72: string, g72: ESObject): string;
    function handleCopyOption(c72: string): CopyOptions;
}
