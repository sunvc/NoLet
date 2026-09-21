// @keepTs
// @ts-nocheck
import { LvLink } from '../domain/LvLink';
import { LvText } from '../domain/LvText';
import { LvFootnoteController } from './controller/lvFootnoteController';
@Component
export declare struct lvFootnoteView {
    @State
    footnoteController: LvFootnoteController;
    @State
    dialogController: CustomDialogController | null;
    @State
    nText: LvText;
    @State
    nLink: LvLink;
    openUrl(u141: string): void;
    build(): void;
}
