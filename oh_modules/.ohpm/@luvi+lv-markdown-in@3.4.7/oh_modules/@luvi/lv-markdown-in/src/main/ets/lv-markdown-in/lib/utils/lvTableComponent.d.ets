// @keepTs
// @ts-nocheck
@Component
export declare struct lvTableComponent {
    @State
    text: string;
    @State
    dialogController: CustomDialogController | null;
    @State
    cellWidthArrayIndexed: number[];
    build(): void;
    @Builder
    lvTableHeadBuilder(w148: string, x148: CustomDialogController | null): void;
    @Builder
    lvTableRowBuilder(b148: string, c148: number, d148: CustomDialogController | null): void;
}
