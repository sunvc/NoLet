// @keepTs
// @ts-nocheck
import { LvFootnoteController } from './utils/controller/lvFootnoteController';
export interface LMICallBack {
    success?: Function;
    fail?: Function;
    code?: string;
    message?: string;
}
/**
 * @deprecated LvMarkdownIn() 组件已弃用，你可以使用导出的 Markdown() 组件
 * @instruction 新版本使用说明：https://ohpm.openharmony.cn/#/cn/detail/@luvi%2Flv-markdown-in
 */
@Component
export default struct lvMarkdownIn {
    /** 纯文本数据，mode：text */
    @Prop
    text: string;
    /** 加载模式：
     * text：纯文本模式
     * rawfile：rawfile资源文件模式
     * sandbox：本地沙箱路径文件模式
     */
    @Prop
    loadMode: "text" | "rawfile" | "sandbox";
    /**
     * 资源文件path
     */
    @Prop
    rawfilePath: string;
    /**
     * 沙箱文件path
     */
    @Prop
    sandboxPath: string;
    /**
     * 应用上下文
     */
    @State
    context: Context | null;
    /**
     * 事件回调
     */
    loadCallBack: LMICallBack;
    @State
    cge: number;
    @State
    private resultData;
    @State
    footnoteController: LvFootnoteController;
    startTime: number;
    private dialogController;
    private imgController;
    textChange(): void;
    cBack(t131: "success" | "fail", u131: string, v131: string): void;
    aboutToAppear(): void;
    _loadRawfile(): void;
    _loadSandbox(): void;
    _readText(x130?: string): void;
    build(): void;
}
