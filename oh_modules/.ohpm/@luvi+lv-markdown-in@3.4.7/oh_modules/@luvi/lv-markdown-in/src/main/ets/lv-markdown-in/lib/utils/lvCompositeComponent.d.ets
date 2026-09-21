// @keepTs
// @ts-nocheck
import { LvLink } from '../domain/LvLink';
import { LvText } from '../domain/LvText';
import { LvFootnoteController } from './controller/lvFootnoteController';
@Component
export declare struct lvCompositeComponent {
    @State
    text: string;
    @State
    nText: LvText;
    @State
    fontWeight: FontWeight;
    @State
    maxLines: number | null;
    @State
    textOverflow: TextOverflow;
    @State
    nLink: LvLink;
    @State
    dialogController: CustomDialogController | null;
    @ObjectLink
    footnoteController: LvFootnoteController;
    @State
    fontSize: number | string;
    @State
    fontColor: number | string;
    openUrl(g139: string): void;
    getLineHeight(): string | number;
    build(): void;
}
