// @keepTs
// @ts-nocheck
import { ImageModel } from '../model/ImageModel';
@Builder
export declare function ImageDialogBuilder(): void;
@Component
export declare struct ImageView {
    @Provide
    isDisableSwipe: boolean;
    @Provide
    isImageReset: boolean;
    private thumbnailSwipeController;
    @Builder
    ImageSwiper(): void;
    aboutToAppear(): void;
    build(): void;
}
@Component
export declare struct ImageItemView {
    @State
    imageData: ResourceStr;
    @State
    imageModel: ImageModel;
    @Consume
    isDisableSwipe: boolean;
    @Consume
    isImageReset: boolean;
    private context;
    private imageWHRatio;
    aboutToAppear(): void;
    onImageReset(): void;
    /**
     * Set information about the current image: uri, whRatio, pixelMap, defaultSize, maxScaleValue
     * Obtain the Image information in advance for the size setting of
     * the image component and subsequent related calculations
     */
    initCurrentImageInfo(): void;
    build(): void;
}
