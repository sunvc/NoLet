// @keepTs
// @ts-nocheck
import { ITitleStyle } from './interface';
@Component
export declare struct lvTitleComponent {
    @State
    text: string;
    @State
    dialogController: CustomDialogController | null;
    @State
    titleStyle: ITitleStyle;
    build(): void;
}
