// 对应 iOS NetworkModel.swift：服务端统一响应包装
export interface BaseResponse<T> {
  code: number;
  message: string;
  data?: T;
  timestamp?: number;
}

// 对应 iOS DeviceInfo：POST /register 的请求体与响应 data。
// JSON 键与服务端约定为 key/token/...（CodingKeys），可选字段缺省时不序列化。
export class DeviceInfo {
  key: string = '';
  token: string = '';
  talk?: string;
  location?: string;
  voip?: string;
  group?: string;
  core?: number;
}
