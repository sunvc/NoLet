export interface LowCodeCommonResult<T> {
  /**
   *获取连接器函数执行后返回的对象
   */
  getValue(): T | null;
}

export interface InvokeOptions {
  connectorId: string; // 连接器id
  methodName: string; // 方法名称
  params?: any; // 方法参数
  timeout?: number; // 超时时间
  version?: string; // 使用云函数的版本，默认latest
}

export interface InvokeResponse {
  ret: {
    code: number;
    msg: string;
  };
  response: {};
}

export enum DataModelType {
  DRAFT = 0,
  RELEASE = 1
}

export interface DataModelOptions {
  modelId: string; // 模型实例Id
  methodName: string; // operationType
  status: DataModelType; // 0：lowcode-draft-model-instance; 1：lowcode-release-model-instance
  params?: DataModelParams; // 方法参数
  timeout?: number; // 超时时间
  version?: string; // 使用云函数的版本，默认latest
}

export enum OrderType {
  ASC = 'asc',
  DESC = 'desc'
}

export interface DataModelParams {
  pageNo?: number; // list接口返回
  pageSize?: number; // list接口返回
  orderBy?: string; // 排序字段名称
  orderType?: OrderType; // asc or desc
  object?: {};
  objects?: {}[];
  primaryKey?: {
    field: string;
    value: string;
  };
  conditions?: Condition[];
  showRelate?: boolean;
  insertWhenNoneExist?: boolean; // 更新数据时，若不存在则新建
}

export interface Condition {
  relation: string;
  field: string;
  value: string;
}

export interface DataModelResponse {
  ret: {
    code: number;
    msg: string;
  };
  data: {
    count?: number; // 增删改接口返回此值
    record?: any; // get接口返回
    records?: any[]; // list接口返回
    total?: number; // list接口返回
    pageNo?: number; // list接口返回
    pageSize?: number; // list接口返回
  };
}

export interface LowCode {
  /**
   *通过connectorId的设置调用哪个连接器的函数
   */
  callConnector(options: InvokeOptions): Promise<LowCodeCommonResult<InvokeResponse>>;

  /**
   *调用DataModel
   */
  callDataModel(options: DataModelOptions): Promise<LowCodeCommonResult<DataModelResponse>>;

  /**
   * 获取云存储文件的临时访问链接
   */
  getFileURL(fileIds: string | string[]): Promise<{ [key: string]: string }>;
}
