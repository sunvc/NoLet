// @keepTs
// @ts-nocheck
import { LvText } from '../domain/LvText';
@Component
export declare struct lvHTMLFontComponent {
    @State
    text: string;
    @State
    nText: LvText;
    build(): void;
}
