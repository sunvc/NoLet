// @keepTs
// @ts-nocheck
import { ImageNode } from '../model/TreeNode';
/**
 * @deprecated
 */
@Component
export declare struct ImageRender {
    @Consume
    markdownUnion: string;
    @State
    image: ImageNode | undefined;
    build(): void;
}
