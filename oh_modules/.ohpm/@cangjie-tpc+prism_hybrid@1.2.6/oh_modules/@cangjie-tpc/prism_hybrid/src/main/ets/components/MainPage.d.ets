import collections from "@arkts.collections";
export declare function codeStringToColorString(code: string, info: string | undefined, isDarkula: boolean): Promise<PrismRes>;
export declare function codeStringToColorStringCustomize(code: string, info: string | undefined, background: number, text: number, colorMap: Map<PrismColor, number>): PrismRes;
@Sendable
export declare class PrismRes {
    list: collections.Array<PrismBlock>;
    background: number;
    defaultFontColor: number;
    constructor(list: collections.Array<PrismBlock>, background: number, defaultFontColor: number);
    /**
     * 获取代码块整体背景色
     *
     * @return 返回代码块整体背景色
     */
    getBackground(): number;
    /**
     * 获取代码块默认文本颜色
     *
     * @return 返回代码块默认文本颜色
     */
    getDefaultFontColor(): number;
    /**
     * 获取块文本内容
     *
     * @return 返回块文本内容
     */
    getListColor(): collections.Array<PrismBlock>;
    addNode(res: PrismNode): void;
    addBlock(): void;
}
@Sendable
export declare class PrismBlock {
    text: string;
    list: collections.Array<PrismNode>;
    /**
     * 获取块文本内容
     *
     * @return 返回块文本内容
     */
    getText(): string;
    /**
     * 获取块的子节点列表信息
     *
     * @return 返回块的子节点列表信息
     */
    getList(): collections.Array<PrismNode>;
}
@Sendable
export declare class PrismNode {
    types: string;
    text: string;
    alias: string | undefined;
    color: number | undefined;
    constructor(types: string, text: string, alias: string | undefined, color: number | undefined);
    /**
     * 获取结果对象类型
     *
     * @return 返回结果对象的类型
     */
    getType(): string;
    /**
     * 获取结果对象文本
     *
     * @return 返回结果对象的文本信息
     */
    getText(): string;
    /**
     * 获取结果对象别名
     *
     * @return 返回结果对象的别名
     */
    getAlias(): string | undefined;
    /**
     * 获取结果对象文本对应的颜色
     *
     * @return 返回结果对象文本对应的颜色
     */
    getColor(): number | undefined;
}
export declare enum PrismColor {
    COMMENT = "comment",
    PROLOG = "prolog",
    DOCTYPE = "doctype",
    CDATA = "cdata",
    PUNCTUATION = "punctuation",
    PROPERTY = "property",
    TAG = "tag",
    BOOLEAN = "boolean",
    NUMBER = "number",
    CONSTANT = "constant",
    SYMBOL = "symbol",
    DELETED = "deleted",
    SELECTOR = "selector",
    ATTR_NAME = "attr-name",
    STRING = "string",
    CHAR = "char",
    BUILTIN = "builtin",
    INSERTED = "inserted",
    OPERATOR = "operator",
    URL = "url",
    ENTITY = "entity",
    ATRULE = "atrule",
    ATTR_VALUE = "attr-value",
    KEYWORD = "keyword",
    FUNCTION = "function",
    CLASS_NAME = "class-name",
    REGEX = "regex",
    IMPORTANT = "important",
    VARIABLE = "variable",
    DELIMITER = "delimiter",
    ANNOTATION = "annotation",
    ESCAPE_SEQ = "escape_seq",
    GENERIC_METHOD = "generic-method",
    PSEUDO_ELEMENT = "pseudo-element",
    PSEUDO_CLASS = "pseudo-class",
    CLASS = "class",
    ID = "id",
    ATTRIBUTE = "attribute",
    HEXCODE = "hexcode",
    COMMAND = "command",
    PARAMETER = "PARAMETER",
    COORD = "coord",
    COMMIT_SHA1 = "commit_sha1",
    SPOCK_BLOCK = "spock-block",
    NULL = "null",
    NAMESPACE = "namespace",
    SHEBANG = "shebang",
    DEFAULT = "default"
}
