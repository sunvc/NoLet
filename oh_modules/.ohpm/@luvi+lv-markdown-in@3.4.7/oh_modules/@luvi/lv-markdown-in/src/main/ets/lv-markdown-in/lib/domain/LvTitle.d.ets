// @keepTs
// @ts-nocheck
@Observed
declare class LvTitle {
    private level1Title;
    private level2Title;
    private level3Title;
    private level4Title;
    private level5Title;
    private level6Title;
    private levelTitleColor;
    setLevel1Title(m126: number | string): void;
    setLevel2Title(l126: number | string): void;
    setLevel3Title(k126: number | string): void;
    setLevel4Title(j126: number | string): void;
    setLevel5Title(i126: number | string): void;
    setLevel6Title(h126: number | string): void;
    setLevelTitleColor(g126: string): void;
    getLevel1Title(): number | string;
    getLevel2Title(): number | string;
    getLevel3Title(): number | string;
    getLevel4Title(): number | string;
    getLevel5Title(): number | string;
    getLevel6Title(): number | string;
    getLevelTitleColor(): string;
}
declare const lvTitle: LvTitle;
export { lvTitle, LvTitle };
