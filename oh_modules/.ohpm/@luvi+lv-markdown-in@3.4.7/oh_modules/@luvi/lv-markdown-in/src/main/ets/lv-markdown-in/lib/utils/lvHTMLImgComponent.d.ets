// @keepTs
// @ts-nocheck
import { LvImage } from '../domain/LvImage';
@Component
export declare struct lvHTMLImgComponent {
    @State
    text: string;
    @State
    nImage: LvImage;
    @State
    dialogController: CustomDialogController | null;
    build(): void;
}
