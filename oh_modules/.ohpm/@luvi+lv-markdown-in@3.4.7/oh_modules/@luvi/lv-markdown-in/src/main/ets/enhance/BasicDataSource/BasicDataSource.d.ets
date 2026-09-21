// @keepTs
// @ts-nocheck
import { TreeNode } from "../model/TreeNode";
export declare class BasicDataSource implements IDataSource {
    private listeners;
    private originDataArray;
    totalCount(): number;
    getData(p: number): TreeNode;
    registerDataChangeListener(o: DataChangeListener): void;
    unregisterDataChangeListener(m: DataChangeListener): void;
    notifyDataReload(): void;
    notifyDataAdd(j: number): void;
    notifyDataChange(h: number): void;
    notifyDataDelete(f: number): void;
    notifyDataMove(c: number, d: number): void;
    notifyDatasetChange(a: DataOperation[]): void;
}
