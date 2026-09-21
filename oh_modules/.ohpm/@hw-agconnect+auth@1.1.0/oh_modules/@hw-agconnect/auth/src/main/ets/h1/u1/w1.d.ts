export declare function replace(packageName: string, config: any): any;
/**
 * 解析 JSON 中的 $ref 引用，并替换为实际值
 * @param data 当前需要解析的数据（可能是对象、数组或基本类型）
 * @param root 整个 JSON 数据的根对象，用于解析 $ref 路径
 * @returns 返回解析后的数据（无 $ref）
 */
export declare function resolveRefs(data: any, root: any): any;
