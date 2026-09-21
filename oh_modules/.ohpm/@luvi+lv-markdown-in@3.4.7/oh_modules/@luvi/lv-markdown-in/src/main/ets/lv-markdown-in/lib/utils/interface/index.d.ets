// @keepTs
// @ts-nocheck
export interface ITextStyle {
    textSize: number | string;
    textColor: string;
    textMarkBackground: string;
}
export interface ITitleStyle {
    level1Tile: number | string;
    level2Tile: number | string;
    level3Tile: number | string;
    level4Tile: number | string;
    level5Tile: number | string;
    level6Tile: number | string;
    levelTitleColor: string;
}
export interface ILinkStyle {
    textSize: number | string;
    textColor: string;
    textUnderline: boolean;
}
export interface IImgStyle {
    imgWidth: number | string;
    imgHeight: number | string | null;
    confGlobal: boolean;
}
export interface IQuoteStyle {
    backgroundColor: string;
    borderColor: string;
}
export interface IState {
    radius: number;
}
