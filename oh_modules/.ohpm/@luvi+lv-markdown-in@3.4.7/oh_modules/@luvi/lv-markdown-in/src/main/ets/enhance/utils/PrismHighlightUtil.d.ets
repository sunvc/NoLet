// @keepTs
// @ts-nocheck
import { CodeHighlight } from '../model/CodeHighlight';
import { HighlightNode } from '../model/highlightNode';
export declare namespace PrismHighlightUtil {
    function makeCacheKey(x118: string, y118: CodeHighlight, z118?: string, a119?: boolean): string;
    function highlight(k118: string, l118: CodeHighlight, m118?: string, n118?: boolean, o118?: string): Promise<HighlightNode[]>;
    function getCached(e118: string, f118: CodeHighlight, g118?: string, h118?: boolean): HighlightNode[] | undefined;
}
