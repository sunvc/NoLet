// @keepTs
// @ts-nocheck
import { TreeNode } from '../model/TreeNode';
@Component
export declare struct IntactRender {
    @Consume
    markdownUnion: string;
    @Prop
    children: TreeNode[];
    @Prop
    lazyRender: boolean;
    @Prop
    preloadBlockCount: number;
    private readonly lazyGroupSize;
    private getNodeRenderKey;
    private getLazyGroupStartIndexes;
    private getPreloadGroupCount;
    private getLazyGroupChildren;
    build(): void;
}
