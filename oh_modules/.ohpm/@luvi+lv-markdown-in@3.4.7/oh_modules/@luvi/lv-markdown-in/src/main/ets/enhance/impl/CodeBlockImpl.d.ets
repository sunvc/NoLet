// @keepTs
// @ts-nocheck
import { CodeTheme } from '../constant/CodeTheme';
import { TreeNode } from '../model/TreeNode';
export declare namespace CodeBlockImpl {
    function handleBackgroundColor(z69: CodeTheme): "#181A1F" | "#F9FAFB";
    function handleThemeChange(x69: string, y69: CodeTheme): void;
    function copyText(v69: string, w69: string): Promise<void>;
    function handleCodeBlockBorderRadius(u69: string): number | ResourceStr;
    function handleCodeHighlight(s69: string, t69: CodeTheme): void;
    function setExtend(p69: TreeNode, ...q69: [
        string,
        ESObject
    ][]): void;
}
