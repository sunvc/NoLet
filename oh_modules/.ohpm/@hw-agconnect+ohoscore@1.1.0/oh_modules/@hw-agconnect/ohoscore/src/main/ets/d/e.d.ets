// @keepTs
// @ts-nocheck
export declare class SafeJson {
    private static j;
    /**
     * 主动捕获JSON.parse异常，防止crash
     * @param inStr 待解析json字符串
     * @param reviver 对结果进行变换的函数。对象的每个成员都调用这个函数。
     * @returns json对象
     */
    static parse(i: string, reviver?: (this: ESObject, key: string, value: ESObject) => ESObject): ESObject;
    /**
     * 主动捕获JSON.stringify异常，防止crash
     * @param value 待解析json对象
     * @param replacer 字符串和数字的数组
     * @param space space向返回值JSON文本添加缩进、空白和换行字符，使其更易于阅读。
     * @returns json解析后的字符串
     */
    static jsonStringifyArray(value: ESObject, replacer?: (number | string)[] | null, space?: string | number): string;
    /**
     * 主动捕获JSON.stringify异常，防止crash
     * @param value 待解析json对象
     * @param replacer 对结果进行变换的函数
     * @param space space向返回值JSON文本添加缩进、空白和换行字符，使其更易于阅读。
     * @returns json解析后的字符串
     */
    static jsonStringify(value: ESObject, replacer?: (this: ESObject, key: string, value: ESObject) => ESObject, space?: string | number): string;
}
