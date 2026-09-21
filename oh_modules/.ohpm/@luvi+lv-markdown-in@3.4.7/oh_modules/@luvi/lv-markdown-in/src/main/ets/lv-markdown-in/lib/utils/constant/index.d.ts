declare enum LV_MD_CONTENT_TYPE {
    TITLE = "title",
    TEXT = "text",
    QUOTE = "quote",
    URL = "url",
    IMG = "img",
    LINE = "line",
    CODE = "code",
    TABLE = "table",
    TABULATE = "tabulate",
    CHECKBOX = "checkbox",
    HTMLIMG = "htmlImg",
    HTMLFONT = "htmlFont",
    FOOTNOTE = "footNote"
}
declare enum LV_MD_DATA_TYPE {
    FLAG = 0,
    MSG = 1
}
declare enum LV_TEXT_TYPE {
    L_BOLD = "lvTextBold",
    L_ITALIC = "lvTextItalic",
    L_MARK = "lvTextMark",
    L_DEL = "lvTextDel",
    L_PINK = "lvTextPink"
}
declare const SP_TYPE: {
    SPK: string;
    SPL: string;
};
export { LV_MD_CONTENT_TYPE, LV_MD_DATA_TYPE, LV_TEXT_TYPE, SP_TYPE };
