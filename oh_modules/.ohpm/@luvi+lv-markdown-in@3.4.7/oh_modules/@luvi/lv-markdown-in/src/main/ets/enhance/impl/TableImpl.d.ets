// @keepTs
// @ts-nocheck
import { TableNode } from '../model/TreeNode';
import drawing from "@ohos.graphics.drawing";
export declare namespace TableImpl {
    function getTableWidths(z71: TableNode | undefined): number[] | undefined;
    function setTableWidths(x71: TableNode | undefined, y71: number[]): void;
    function handleTableBackgroundColor(w71: string): ResourceColor;
    function handleTableTitleBackgroundColor(v71: string): ResourceColor;
    function handleTableTitleTextColor(u71: string): ResourceColor;
    function handleTableInterleaveTextColor(t71: string): ResourceColor;
    function handleTableNormalTextColor(s71: string): ResourceColor;
    function handleTableInterleaveBackgroundColor(r71: string): ResourceColor;
    function handleTableActionBackgroundColor(q71: string): ResourceColor;
    function handleTableActionIconColorFilter(o71: string): drawing.ColorFilter;
    function handleTableBorderRadius(n71: string): ResourceStr | number;
    function handleTableOuterBorderColor(m71: string): ResourceColor | null;
    function handleTableOuterBorderWidth(l71: string): ResourceStr | number;
    function handleTableInnerBorderColor(k71: string): ResourceColor | null;
    function handleTableInnerBorderWidth(j71: string): ResourceStr | number;
    function handleTableAlign(i71: string): FlexAlign;
    function handleTextAlign(h71: "none" | "left" | "center" | "right" | string | undefined): HorizontalAlign;
}
