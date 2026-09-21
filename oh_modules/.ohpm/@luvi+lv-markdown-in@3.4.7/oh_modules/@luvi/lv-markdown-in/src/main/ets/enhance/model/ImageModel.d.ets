// @keepTs
// @ts-nocheck
import matrix4 from "@ohos.matrix4";
import window from "@ohos.window";
import image from "@ohos.multimedia.image";
@Observed
export declare class ImageModel {
    matrix: matrix4.Matrix4Transit;
    curScale: number;
    curOffsetX: number;
    curOffsetY: number;
    lastScale: number;
    lastOffsetX: number;
    lastOffsetY: number;
    minScale: number;
    maxScale: number;
    defaultScaleValue: number;
    maxOffsetX: number;
    minOffsetX: number;
    maxOffsetY: number;
    minOffsetY: number;
    centerX: number;
    centerY: number;
    center: number[];
    componentHeight: number;
    componentWidth: number;
    imageWidth: number;
    imageHeight: number | undefined;
    isDisableSwipe: boolean;
    constructor(v90?: matrix4.Matrix4Transit, w90?: number, x90?: number, y90?: number, z90?: number, a91?: number, b91?: number, c91?: number, d91?: number, e91?: number, f91?: number, g91?: number, h91?: number, i91?: number, j91?: number, k91?: number, l91?: [
        number,
        number
    ], m91?: number, n91?: number, o91?: number, p91?: number | undefined, q91?: boolean);
    gestureEnd(): void;
    imageReset(): void;
    offsetReset(): void;
    windowSize(): void;
    pictureScaling(r90: number): void;
    evaluateOffsetRange(): void;
    evaluateCenter(j90: number, k90: number): [
        number,
        number
    ];
    calcFitScaleRatio(g90: image.Size, h90: window.Size): number;
    panGestureUpdate(f90: GestureEvent): boolean;
    pinchGestureStart(e90: GestureEvent): void;
    pictureBoundaryRestriction(): void;
    pinchGestureUpdate(d90: GestureEvent): boolean;
    pinchGestureEnd(): void;
    doubleTapGesture(b90: GestureEvent): boolean;
    onScale(y89: number, z89: number, a90: number): void;
}
/**
 * Status bar title and icon.
 */
export declare class ImageInfo {
    icon?: Resource;
    name?: Resource;
    constructor(w89: Resource, x89: Resource);
}
