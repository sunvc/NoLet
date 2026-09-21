export declare interface CustomLib {
    latexStringToImage(latexMathTextString: string, latexMathTextSize: number, latexMathTextColor: number, latexMathBackGroupColor: number, latexMathColorFormat: number, resPath: string): Promise<ArrayBuffer>;
    latexStringToImageWithError(latexMathTextString: string, latexMathTextSize: number, latexMathTextColor: number, latexMathBackGroupColor: number, latexMathColorFormat: number, resPath: string): Promise<TeXParseResult>;
}
/**
 * 图片格式枚举
 */
export declare enum LatexMathColorFormat {
    COLOR_FORMAT_RGB_565 = 0,
    COLOR_FORMAT_BGRA_8888 = 1
}
/**
 * TeX解析结果码枚举
 */
export declare enum TeXResultCode {
    Success = 0,
    SyntaxError = 1,
    InvalidMatrixError = 2,
    InvalidDelimiterError = 3,
    TeXError = 4,
    UnknownError = 99
}
/**
 * TeX解析结果
 */
export interface TeXParseResult {
    imageBytes: ArrayBuffer;
    formula: string;
    resultCode: TeXResultCode;
    errorMessage: string;
}
/**
 * 数学公式文本转换图片数组数据
 *
 * @param latexMathTextString 数学公式文本
 * @param latexMathTextSize 文本大小
 * @param latexMathTextColor 文本颜色
 * @param latexMathBackGroupColor 背景色
 * @param latexMathColorFormat 图片格式
 * @param resPath 字体资源路径
 * @returns 图片数组数据
 */
export declare function latexStringToImage(latexMathTextString: string, latexMathTextSize: number, latexMathTextColor: number, latexMathBackGroupColor: number, latexMathColorFormat: LatexMathColorFormat, resPath?: string): Promise<ArrayBuffer>;
/**
 * 数学公式文本转换图片数组数据（带错误信息）
 * 当公式解析失败时，返回详细的错误信息
 *
 * @param latexMathTextString 数学公式文本
 * @param latexMathTextSize 文本大小
 * @param latexMathTextColor 文本颜色
 * @param latexMathBackGroupColor 背景色
 * @param latexMathColorFormat 图片格式
 * @param resPath 字体资源路径
 * @returns TeXParseResult 解析结果，通过 resultCode 判断成功/失败
 */
export declare function latexStringToImageWithError(latexMathTextString: string, latexMathTextSize: number, latexMathTextColor: number, latexMathBackGroupColor: number, latexMathColorFormat: LatexMathColorFormat, resPath?: string): Promise<TeXParseResult>;
