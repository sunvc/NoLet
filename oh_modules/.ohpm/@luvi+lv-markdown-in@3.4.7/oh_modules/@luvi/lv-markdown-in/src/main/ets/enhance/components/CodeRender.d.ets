// @keepTs
// @ts-nocheck
import { CodeBlockNode } from '../model/TreeNode';
@Component
export declare struct CodeRender {
    @Consume
    markdownUnion: string;
    @Prop
    base: CodeBlockNode | undefined;
    private isPreviewSuppressed;
    private isMermaidCodeBlock;
    private isHtmlCodeBlock;
    private isActionAreaVisible;
    build(): void;
}
