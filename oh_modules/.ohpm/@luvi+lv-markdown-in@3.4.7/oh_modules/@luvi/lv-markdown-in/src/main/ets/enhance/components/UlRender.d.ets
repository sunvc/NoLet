// @keepTs
// @ts-nocheck
import { TreeNode } from '../model/TreeNode';
@Component
export declare struct UlRender {
    @Consume
    markdownUnion: string;
    @State
    base: TreeNode | undefined;
    @State
    idxWidth: Length[];
    aboutToAppear(): void;
    build(): void;
}
