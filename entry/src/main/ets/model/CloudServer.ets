import { cloudDatabase } from '@kit.CloudFoundationKit';

/// 云数据库实体：对应 AGC 对象类型「Server」（历史服务器）
/// 主键：user（华为 unionID）+ key（服务器 KEY）
export class CloudServer extends cloudDatabase.DatabaseObject {
  createDate: Date = new Date();
  /// 华为账号 unionID（同一开发者账号下跨应用一致）
  user: string = '';
  /// 服务器 KEY（主键，空串表示无 KEY 的服务器）
  key: string = '';
  url: string = '';

  naturalbase_ClassName(): string {
    return 'Server';
  }
}
