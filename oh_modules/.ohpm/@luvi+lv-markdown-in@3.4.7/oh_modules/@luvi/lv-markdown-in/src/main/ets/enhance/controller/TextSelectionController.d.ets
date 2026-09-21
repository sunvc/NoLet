// @keepTs
// @ts-nocheck
import componentUtils from "@ohos.arkui.componentUtils";
import { BlockHitInfo, BlockSelectionStartInfo, RegisteredTextBlock, TextSelectionSegment } from '../model/TextSelectionInfo';
export declare class TextSelectionController {
    private static controllerMap;
    private static activeMarkdownUnion?;
    private markdownUnion;
    private blocks;
    private orderedBlocksCache;
    private blockRectCache;
    private layoutCacheValid;
    private nextOrder;
    private readonly HIT_SLOP;
    private startSelectionHandler?;
    private updateSelectionHandler?;
    private endSelectionHandler?;
    private clearSelectionHandler?;
    private constructor();
    static getInstance(f63: string): TextSelectionController;
    static destroy(e63: string): void;
    registerBlock(x62: string, y62: TextController, z62: TextSelectionSegment[]): void;
    unregisterBlock(w62: string): void;
    clear(): void;
    setStartSelectionHandler(v62?: (info: BlockSelectionStartInfo) => void): void;
    setUpdateSelectionHandler(u62?: (globalX: number, globalY: number) => void): void;
    setEndSelectionHandler(t62?: () => void): void;
    setClearSelectionHandler(s62?: () => void): void;
    releaseActiveSelection(): void;
    triggerStartSelection(q62: BlockSelectionStartInfo): void;
    triggerUpdateSelection(o62: number, p62: number): boolean;
    triggerEndSelection(): boolean;
    getOrderedBlocks(): RegisteredTextBlock[];
    private refreshLayoutSnapshot;
    getBlockByOrder(e62: number): RegisteredTextBlock | undefined;
    getBlockById(d62: string): RegisteredTextBlock | undefined;
    getExactBlockInfoByPoint(t61: number, u61: number): BlockHitInfo | undefined;
    getNearestBlockInfoByPoint(e61: number, f61: number): BlockHitInfo | undefined;
    getBlockInfoByPoint(t60: number, u60: number): BlockHitInfo | undefined;
    getBlockRect(q60: string, r60?: boolean): componentUtils.ComponentInfo | undefined;
    invalidateLayoutCache(): void;
    private loadBlockRect;
    buildCopyText(z59: number, a60: number, b60: number, c60: number): string;
    private extractBlockCopyText;
}
