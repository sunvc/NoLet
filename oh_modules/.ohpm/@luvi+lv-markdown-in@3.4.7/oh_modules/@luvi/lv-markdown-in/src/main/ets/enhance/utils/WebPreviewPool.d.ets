// @keepTs
// @ts-nocheck
import webview from "@ohos.web.webview";
import { FrameNode } from "@ohos.arkui.node";
import { NodeController } from "@ohos.arkui.node";
import { UIContext } from "@ohos.arkui.UIContext";
declare class WebPreviewPoolNodeData {
    src: string;
    controller: webview.WebviewController;
    javaScriptAccess: boolean;
    onProgressChange: (progress: number) => void;
    onPageEnd: () => void;
}
export declare class WebPreviewNodeController extends NodeController {
    private rootNode;
    private root;
    private slot;
    constructor(m124: WebPreviewPoolSlot);
    isBuilt(): boolean;
    ensureBuilt(l124: UIContext): void;
    updateData(): void;
    makeNode(g124: UIContext): FrameNode | null;
    aboutToDisappear(): void;
    dispose(): void;
}
export declare class WebPreviewPoolRequest {
    ownerKey: string;
    src: string;
    javaScriptAccess: boolean;
    uiContext: UIContext;
    initialSize: number;
    maxSize: number;
    idleRetain: number;
    onProgressChange: (progress: number) => void;
    onPageEnd: () => void;
    onAcquired: (slot: WebPreviewPoolSlot) => void;
    constructor(v156: string, w156: string, x156: boolean, y156: UIContext);
}
export declare class WebPreviewPoolSlot {
    readonly id: number;
    readonly nodeController: WebPreviewNodeController;
    private data;
    private webController;
    private ownerKey;
    private busy;
    private lastUsedAt;
    private mounted;
    private pendingLoad;
    constructor(w123: number);
    getNodeData(): WebPreviewPoolNodeData;
    isBusy(): boolean;
    getOwnerKey(): string;
    getLastUsedAt(): number;
    preload(v123: UIContext): void;
    assign(u123: WebPreviewPoolRequest): void;
    release(s123: string): boolean;
    onMounted(): void;
    onDetached(): void;
    dispose(): void;
    private loadUrl;
}
export declare class WebPreviewPool {
    private static instance;
    private slots;
    private waitingRequests;
    private nextSlotId;
    private initialSize;
    private maxSize;
    private idleRetain;
    private trimTimer;
    private webEngineInitialized;
    static getInstance(): WebPreviewPool;
    preload(k123: UIContext, l123: number, m123: number, n123: number): void;
    request(h123: WebPreviewPoolRequest): WebPreviewPoolSlot | null;
    release(f123: string): void;
    cancel(e123: string): void;
    private configure;
    private ensureWebEngineInitialized;
    private prepareInitialSlots;
    private createSlot;
    private findOwnerSlot;
    private findIdleSlot;
    private assignWaitingRequest;
    private removeWaitingRequest;
    private cancelTrimTimer;
    private scheduleTrimTimer;
    private trimIdleSlots;
}
export {};
