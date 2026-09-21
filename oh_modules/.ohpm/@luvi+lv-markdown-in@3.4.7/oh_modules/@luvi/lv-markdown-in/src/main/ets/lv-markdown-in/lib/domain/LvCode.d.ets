// @keepTs
// @ts-nocheck
type Theme = "light" | "dark";
@Observed
declare class LvCode {
    private theme;
    private indexState;
    setTheme(r125: Theme): void;
    setIndexState(q125: boolean): void;
    getTheme(): string;
    getIndexState(): boolean;
}
declare const lvCode: LvCode;
export { lvCode, LvCode };
