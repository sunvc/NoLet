// 用户配置的推送服务器（对应 iOS PushServerModel）
@ObservedV2
export class ServerInfo {
  @Trace id: string = '';
  @Trace url: string = '';
  @Trace key: string = '';
  // 快捷页发送目标的备注名（本机接收用服务器不使用），可空
  @Trace remark: string = '';
  // 快捷页默认服务器（进入应用时自动/确认发送的目标），仅 quickServers 使用
  @Trace isDefault: boolean = false;
  // 注册到服务器时上报的分组（服务端按组投递），可空
  @Trace group: string = '';
  // 最近一次可达性探测/注册结果：0 检测中 / 1 在线 / -1 离线
  @Trace status: number = 0;
}
