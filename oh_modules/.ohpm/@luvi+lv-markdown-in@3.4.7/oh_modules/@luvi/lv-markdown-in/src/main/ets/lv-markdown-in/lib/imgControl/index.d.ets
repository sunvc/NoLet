// @keepTs
// @ts-nocheck
import { LvImage } from '../domain/LvImage';
@CustomDialog
export declare struct ImgControl {
    controller: CustomDialogController;
    @State
    nImage: LvImage;
    build(): void;
}
