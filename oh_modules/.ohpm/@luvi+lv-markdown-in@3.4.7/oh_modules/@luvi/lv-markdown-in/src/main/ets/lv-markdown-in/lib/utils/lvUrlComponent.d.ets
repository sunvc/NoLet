// @keepTs
// @ts-nocheck
import { LvText } from '../domain/LvText';
import { LvLink } from '../domain/LvLink';
@Component
export declare struct lvUrlComponent {
    @State
    text: string;
    @State
    uri: string;
    @State
    nText: LvText;
    @State
    fontSize: number | string;
    @State
    fontWeight: FontWeight;
    @State
    nLink: LvLink;
    @State
    dialogController: CustomDialogController | null;
    build(): void;
}
