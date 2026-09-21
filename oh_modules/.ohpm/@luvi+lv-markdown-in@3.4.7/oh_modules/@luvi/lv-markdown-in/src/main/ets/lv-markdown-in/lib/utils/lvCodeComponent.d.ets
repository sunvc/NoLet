// @keepTs
// @ts-nocheck
import { LvCode } from '../domain/LvCode';
@Component
export declare struct lvCodeComponent {
    @State
    text: string;
    @State
    nCode: LvCode;
    @State
    rowLimit: number;
    @State
    idxWidth: number;
    calcRow(): number;
    showMore(): void;
    build(): void;
}
