// @keepTs
// @ts-nocheck
import { FootnoteNode, TreeNode } from '../model/TreeNode';
@Component
export declare struct FootnotesRender {
    @State
    base: TreeNode | undefined;
    build(): void;
}
@Component
export declare struct Footnote {
    @Consume
    markdownUnion: string;
    @State
    base: TreeNode | undefined;
    @State
    item: FootnoteNode | undefined;
    @State
    titleWidth: Length;
    build(): void;
}
