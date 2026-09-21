// @keepTs
// @ts-nocheck
import { TreeNode } from '../model/TreeNode';
@Component
export declare struct BlockquoteRender {
    @Consume
    markdownUnion: string;
    @State
    base: TreeNode | undefined;
    aboutToAppear(): void;
    private markQuoteNode;
    build(): void;
}
