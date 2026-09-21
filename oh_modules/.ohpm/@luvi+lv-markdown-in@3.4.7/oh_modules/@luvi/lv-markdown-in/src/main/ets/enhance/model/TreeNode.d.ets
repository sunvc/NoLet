// @keepTs
// @ts-nocheck
export interface BaseNode {
    type: string;
    children?: TreeNode[] | FootnoteNode[];
    extend?: Map<string, ESObject>;
    renderKey?: string;
}
export interface TextNode extends BaseNode {
    type: "text";
    text: string;
}
interface BoldNode extends BaseNode {
    type: "bold";
    children: TreeNode[];
}
interface ItalicNode extends BaseNode {
    type: "italic";
    children: TreeNode[];
}
export interface BoldItalicNode extends BaseNode {
    type: "bolditalic";
    children: TreeNode[];
}
interface StrikethroughNode extends BaseNode {
    type: "strikethrough";
    children: TreeNode[];
}
export interface InlineCodeNode extends BaseNode {
    type: "inlineCode";
    text: string;
}
export interface InlineHtmlFontNode extends BaseNode {
    type: "inlineHtmlFont";
    text: string;
    color?: string;
    size?: number;
    face?: string;
}
export interface LinkNode extends BaseNode {
    type: "link";
    text?: string;
    url: string;
    children: TreeNode[];
}
export interface ImageNode extends BaseNode {
    type: "image";
    url: string;
    alt?: string;
    title?: string;
    width?: number;
    height?: number;
}
interface ParagraphNode extends BaseNode {
    type: "paragraph";
    children: TreeNode[];
}
interface HrNode extends BaseNode {
    type: "hr";
}
interface HeadingNode extends BaseNode {
    type: "heading";
    level: 1 | 2 | 3 | 4 | 5 | 6;
    children: TreeNode[];
}
interface BlockquoteNode extends BaseNode {
    type: "blockquote";
    children: TreeNode[];
}
interface ListItemNode extends BaseNode {
    type: "listItem";
    checked?: boolean;
    children: TreeNode[];
}
interface UlNode extends BaseNode {
    type: "ul";
    children: ListItemNode[];
}
interface OlNode extends BaseNode {
    type: "ol";
    children: ListItemNode[];
}
export interface TableCellNode extends BaseNode {
    type: "tableCell";
    children: ParagraphNode[];
}
export interface TableRowNode extends BaseNode {
    type: "tableRow";
    children: TableCellNode[];
}
export interface TableNode extends BaseNode {
    type: "table";
    tableId: number;
    rawMarkdown: string;
    header: TableCellNode[];
    rows: TableRowNode[];
    align?: ("none" | "left" | "center" | "right")[];
}
export interface CodeBlockNode extends BaseNode {
    type: "codeBlock";
    lang?: string;
    text: string;
    closed?: boolean;
}
export interface FootnotesNode extends BaseNode {
    type: "footnotes";
    children: FootnoteNode[];
}
export interface FootnoteNode extends BaseNode {
    id: string;
    children: ParagraphNode[];
}
export interface FootnoteRefNode extends BaseNode {
    type: "footnoteRef";
    id: string;
}
export interface LatexNode extends BaseNode {
    type: "latex";
    block: boolean;
    text: string;
}
export interface PluginNode extends BaseNode {
    type: "plugin";
    pluginKey: string;
    display: "inline" | "block";
    raw: string;
    params?: ESObject;
    groups?: string[];
    copyText?: string;
    selectable?: boolean;
}
export type TreeNode = TextNode | BoldNode | ItalicNode | StrikethroughNode | InlineCodeNode | InlineHtmlFontNode | LinkNode | ImageNode | ParagraphNode | HrNode | HeadingNode | BlockquoteNode | UlNode | OlNode | ListItemNode | TableNode | TableRowNode | TableCellNode | CodeBlockNode | FootnotesNode | FootnoteRefNode | LatexNode | PluginNode | BoldItalicNode;
export {};
