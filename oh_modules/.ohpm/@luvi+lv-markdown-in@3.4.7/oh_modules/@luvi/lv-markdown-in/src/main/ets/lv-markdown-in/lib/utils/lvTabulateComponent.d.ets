// @keepTs
// @ts-nocheck
import { LvText } from '../domain/LvText';
@Component
export declare struct lvTabulateComponent {
    @State
    text: string;
    @State
    nText: LvText;
    @State
    dialogController: CustomDialogController | null;
    build(): void;
}
