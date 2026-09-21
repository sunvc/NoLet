// @keepTs
// @ts-nocheck
import { TableNode } from '../model/TreeNode';
@Component
export declare struct TableRender {
    @Consume
    markdownUnion: string;
    @State
    base: TableNode | undefined;
    @State
    cellWidthArrayIndexed: number[];
    aboutToAppear(): void;
    private getTableCopyClickListener;
    private getTableDownloadClickListener;
    private getTableExpandClickListener;
    private hasTableAction;
    private getTableContentWidth;
    private handleTableCopy;
    private handleTableDownload;
    private handleTableExpand;
    build(): void;
}
