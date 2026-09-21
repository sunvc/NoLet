// @keepTs
// @ts-nocheck
export declare function isPrimaryMouseButton(g122: MouseEvent): boolean;
export declare function clearActiveTextSelectionMouseTracker(): void;
export declare class TextSelectionMouseTracker {
    private pressed;
    private selecting;
    private startLocalX;
    private startLocalY;
    private startGlobalX;
    private startGlobalY;
    handleBlockSelectionMouseEvent(a122: string, b122: string, c122: MouseEvent): void;
    reset(): void;
    private hasDragged;
}
