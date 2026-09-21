// @keepTs
// @ts-nocheck
import { LvImage } from '../domain/LvImage';
@Component
export declare struct lvImgComponent {
    @State
    text: string;
    @State
    nImage: LvImage;
    @State
    dialogController: CustomDialogController | null;
    @State
    imgWidth: number | string;
    @State
    imgHeight: number | string | null;
    build(): void;
}
