// @keepTs
// @ts-nocheck
export interface HighlightNode {
    type: "row";
    code: HighlightCode[];
}
export interface HighlightCode {
    color: string;
    text: string;
    type: string;
}
