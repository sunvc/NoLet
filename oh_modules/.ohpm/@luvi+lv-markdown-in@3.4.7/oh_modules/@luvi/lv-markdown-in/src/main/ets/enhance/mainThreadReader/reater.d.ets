// @keepTs
// @ts-nocheck
import { WorkerParam, WorkerParseReq, WorkerStringResp, WorkerTreeNodeResp } from '../model/WorkerParam';
/**
 * 主线程数据读取
 */
export declare class MainReader {
    static reader(w88: WorkerParam | WorkerStringResp | WorkerParseReq): Promise<WorkerTreeNodeResp | WorkerStringResp>;
}
