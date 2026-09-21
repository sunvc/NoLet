export declare class PrismNodeCJ {
  getType(): string

  getText(): string

  getAlias(): string | undefined

  getColor(): number | undefined
}

export declare class PrismBlockCJ {
  getText(): string

  getList(): Array<PrismNodeCJ>
}

export declare class PrismResCJ {
  getBackground(): number

  getDefaultFontColor(): number

  getListColor(): Array<PrismBlockCJ>
}

export declare interface CustomLib {
  PrismResCJ: { new(list: Array<PrismBlockCJ>, background: number, defaultFontColor: number): PrismResCJ }
  PrismBlockCJ: { new(text: string, list: Array<PrismNodeCJ>): PrismBlockCJ }
  PrismNodeCJ: { new(types: string, text: string, alias: string | undefined, color: number | undefined): PrismNodeCJ }

  arktsCodeStringToColorStringCustomize(code: string, info: string | undefined, background: number, text: number, colorMap: Map<string, number>): PrismResCJ

  /**
   * parse result into js object
   * @param code
   * @param info
   * @param isDarkula
   * @param resFactory: (background: number,defaultFontColor: number)=>PrismRes
   * @param nodeFactory: (types: string,text: string,alias: string | undefined,color: number | undefined)=>PrismBlock
   * @returns Promise<PrismRes>
   */
  arktsCodeStringToColorString(code: string, info: string | undefined, isDarkula: boolean, resColorFactory: (background: number, defaultFontColor: number) => object, resFactory: (types: string, text: string, alias: string | undefined, color: number | undefined) => object): Promise<object>
}