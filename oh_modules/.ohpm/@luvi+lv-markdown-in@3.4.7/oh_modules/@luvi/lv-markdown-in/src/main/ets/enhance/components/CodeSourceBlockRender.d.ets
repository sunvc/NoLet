// @keepTs
// @ts-nocheck
@Component
export declare struct CodeSourceBlockRender {
    @Consume
    selectionUnion: string;
    @Prop
    markdownUnion: string;
    @Prop
    lang: string;
    @Prop
    text: string;
    @Prop
    autoCollapse: boolean;
    @Prop
    selectable: boolean;
    @Prop
    lineNumberWidth: number;
    @Prop
    contentBottomPadding: number;
    @Prop
    actionAreaVisible: boolean;
    @State
    themeVersion: number;
    private codeThemeListener;
    aboutToAppear(): void;
    aboutToDisappear(): void;
    private isDarkTheme;
    private openCodeDialog;
    build(): void;
}
