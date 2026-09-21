// @keepTs
// @ts-nocheck
import { LvQuote } from '../domain/LvQuote';
@Component
export declare struct lvQuoteComponent {
    @State
    text: string;
    @State
    nQuote: LvQuote;
    @State
    dialogController: CustomDialogController | null;
    build(): void;
}
