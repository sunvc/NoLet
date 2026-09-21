import { ServerInfo } from './ServerInfo';
import { Type } from '@kit.ArkUI';
import { CryptoConfig } from './CryptoConfig';

// 全局应用状态（StateStore 中的唯一 state 对象）。
// 纯 @ObservedV2 模型：模块加载时创建，不依赖 UI 实例，任何位置都可通过 appStore 访问。
// 持久化由 AppPersistMiddleware 显式写入 Preferences（status 等瞬时状态不入库）。
@ObservedV2
export class AppStoreModel {
  @Trace pushToken: string = '';
  @Trace deviceId: string = '';
  @Trace firstStart: boolean = true;
  @Trace showGroup: boolean = false;
  @Trace defaultSound: string = 'nolet';
  // 进入应用时剪贴板有内容：true=自动发送给快捷页默认服务器；quickSend=true=弹窗确认后发送
  @Trace autoSend: boolean = false;
  @Trace quickSend: boolean = false;
  // 操作成功时是否震动反馈（更多设置开关），默认开启
  @Trace haptics: boolean = true;
  // 局域网共享：进 App 时把剪贴板内容 UDP 广播给同网段的 Mac
  @Trace lanShare: boolean = false;
  // 局域网共享 6 位接收码（AES-GCM 密钥来源），首次开启时生成
  @Trace lanCode: string = '';
  // 华为账号凭证（登录成功后本地保存）：跨应用 unionID、本应用 openID
  @Trace huaweiUnionID: string = '';
  @Trace huaweiOpenID: string = '';
  // 快捷发送的可选参数（侧边栏配置）：空串表示不带该参数
  // group 默认「快捷消息」，规范值中文、接收端显示时按语言翻译
  @Trace quickTitle: string = '';
  @Trace quickIcon: string = '';
  @Trace quickSound: string = '';
  @Trace quickGroup: string = '快捷消息';
  @Trace servers: ServerInfo[] = [];
  // 快捷页的发送目标服务器（非本机接收用），与 servers 分开持久化
  @Type(ServerInfo)
  @Trace quickServers: ServerInfo[] = [];
  // @Type 声明数组元素类型，持久化才能反序列化回 CryptoConfig 实例
  @Type(CryptoConfig)
  @Trace cryptoConfigs: CryptoConfig[] = [];
}
