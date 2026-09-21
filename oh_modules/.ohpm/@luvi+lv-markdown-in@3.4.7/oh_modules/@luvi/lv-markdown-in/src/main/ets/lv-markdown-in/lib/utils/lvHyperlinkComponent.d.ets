// @keepTs
// @ts-nocheck
import { LvLink } from '../domain/LvLink';
@Component
export declare struct lvHyperlinkComponent {
    @Prop
    text: string;
    @Prop
    uri: string;
    @Prop
    nLink: LvLink;
    @Prop
    fontSize: number | string;
    @Prop
    fontWeight: FontWeight;
    @Prop
    dialogController: CustomDialogController | null;
    build(): void;
}
@Builder
export default function lvHyperlinkBuilder(h144: string, i144: string, j144: LvLink, k144: number | string, l144: FontWeight, m144: CustomDialogController | null): void;
