// @keepTs
// @ts-nocheck
import webView from '@ohos.web.webview';
import { LvLink } from '../domain/LvLink';
@CustomDialog
export declare struct WebControl {
    controller: CustomDialogController;
    webController: webView.WebviewController;
    @State
    mode: MixedMode;
    @State
    loading: boolean;
    @State
    nLink: LvLink;
    build(): void;
}
