// @keepTs
// @ts-nocheck
import { LatexInfo } from '../utils/LatextUtil';
export declare function getLatexText(m2: ESObject): string;
export declare function preloadLatexImage(j2: string, k2: string, l2: UIContext): Promise<void>;
export declare function getCachedLatexImage(h2: string, i2: string): LatexInfo | undefined;
@Builder
export declare function LatexBlockSpanBuilder(y1: string, z1: string, a2: LatexInfo, b2: UIContext): void;
@Builder
export declare function LatexInlineSpanBuilder(t1: string, u1: string, v1: LatexInfo, w1: UIContext): void;
@Builder
export declare function LatexTextFallbackSpanBuilder(n1: string): void;
@Builder
export declare function LatexImageSpanBuilder(g1: string, h1: string, i1: LatexInfo, j1: UIContext): void;
@Builder
export declare function LatexBlockImageBuilder(v: string, w: string, x: LatexInfo, y: UIContext): void;
