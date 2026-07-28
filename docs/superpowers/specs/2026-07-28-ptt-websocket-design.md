# PTT WebSocket 模式设计

日期: 2026-07-28

涉及仓库:
- iOS: /Users/lynn/XcodeProject/NoLet
- 服务端 (Go): /Users/lynn/GolandProjects/NoLets

## 背景

当前 Push-to-Talk 采用两条独立通道:
- Presence(在线成员 / 地图位置)走 SSE: POST /ptt/subscribe 推送 snapshot/join/leave/update,POST /ptt/presence 做位置心跳。
- 语音走 APNs: 录完整段 Opus -> POST /ptt/voice -> 服务端 MsgQueue -> push.PttPush 发 APNs PTT 推送(携带 url)-> 接收方 incomingPushResult 从 GET /ptt/voice/:name 下载并播放。

语音全程绕经 APNs,前台在线时延迟偏高;presence 与语音是两套长连接/请求,连接状态难统一。

## 目标

用一条 WebSocket 在前台承载 presence 与语音的实时收发,APNs 退化为「接收方无活跃 WS 时」的后台/锁屏兜底唤醒。前台低延迟,后台保留锁屏自动播放能力。

## 决策记录(已与用户确认)

1. WebSocket 承载范围: presence + 语音全部合并到一条 WS,取代现有 SSE。
2. 语音传输方式: 整段 Opus 传输(改动最小),复用现有录制/加密/落盘/AudioMessage 状态机。实时分片作为后续迭代。
3. 接收播放: 复用现有 PTT 状态机,收到 WS 语音后落盘为 AudioMessage,走 send(.startPlay(voice), remote: true),与 APNs 入口行为一致。
4. WS 与 APNs 协调: 服务端按接收者「是否有活跃 WS」择一投递,单人只收到一条,无需客户端去重。
5. 旧接口: 彻底替换。下线 SSE/presence/voice-POST,保留 GET /ptt/voice/:name(APNs 兜底下载)与 POST /ptt/connect(首屏快照)。新增 WS 接口。
6. 连接生命周期: 前台连、后台断。回前台重连并拉 snapshot。
7. 在线判定: 用「是否在频道(已加入)」判定在线,不用「WS 是否连接」。成员身份与 WS 连接解耦。
8. 频道退出: 只靠显式离开,不设 TTL。App 被强杀等极端情况接受「幽灵残留」,由对方下次重连拉 snapshot 对齐纠正。
9. 位置上报: 经纬度变化驱动(复用现有 .locationUpdated 通知 + 5s 节流),上报通道从 POST /ptt/presence 改为 WS 文本帧。

## 架构

一条 WebSocket GET /ptt/ws 在前台承载:presence 事件、位置心跳、语音上传与下发。

成员身份(在频道 = 在线)与 WS 连接解耦:
- 频道成员身份(= 在线,用于 presence/地图): 由显式加入/退出驱动(powerState 开 -> 加入,关 -> 退出),不随 WS 断开消失。
- WS 活跃状态(仅用于选投递通道): 瞬时。转发语音时,成员当前有活的 WS -> 走 WS 推;无活 WS(如切后台)-> 走 APNs。成员身份决定「发给谁」,WS 活跃只决定「怎么发」。

## WebSocket 协议 (/ptt/ws)

握手复用现有签名头鉴权(CryptoManager.signature 生成的 X-Device / X-USER / Authorization / X-Signature),经由现有 Verification() 全局中间件之后进入 handler。

连接建立后:
1. 客户端发 hello 文本帧: JSON { id, channels, latitude, longitude, token, host }(等价现有 JoinParams)。
2. 服务端注册用户到频道成员表 + 标记该用户「有活跃 WS」,广播 join,并回一条 snapshot(订阅频道当前成员)。

之后:
- 文本帧 = JSON 控制消息:
  - presence 事件下发(复用现有 PresenceEvent / SubEvent 结构: snapshot/join/leave/update)。
  - 客户端位置心跳: { type: "presence", latitude, longitude } -> 服务端 BroadcastUpdate 广播 update。
  - 客户端离开: { type: "leave" } -> 移出成员表,广播 leave。
  - 保活: WS ping/pong。
- 二进制帧 = 语音单帧封装(原子,无需配对):
  - [4 字节大端: 元数据长度 N]
  - [N 字节: 元数据 JSON: { channel, file, sign, sender }]
  - [剩余字节: Opus 音频数据]

## 语音路径

发送(在线):
1. 录完整段 Opus(复用现有录制/加密/命名 channel-id-timestamp.ogg)。
2. 通过 WS 二进制帧上报(元数据 + 音频)。
3. 服务端落盘到 data/voices/(供 APNs 兜底下载),然后对频道内每个「其他成员」按是否有活跃 WS 择一投递:
   - 有活跃 WS -> 直接推二进制帧。
   - 无活跃 WS -> 走现有 MsgQueue -> PttPush APNs 路径(携带 GET /ptt/voice/:name 的 url)。

接收(两条入口行为一致):
- WS 入口: 收到二进制帧 -> 解出元数据 + 音频 -> 落盘为 AudioMessage -> send(.startPlay(voice), remote: true)。
- APNs 入口: 现有 incomingPushResult -> saveVoice(remoteUrl:) -> send(.startPlay(voice), remote: true)(保持不变)。

## 客户端生命周期与位置上报

- 连接时机: sceneWillEnterForeground 且 powerState == true -> 连 WS;sceneDidEnterBackground -> 断 WS(成员身份保留,语音回落 APNs);回前台重连并拉 snapshot。
- 位置上报: 保留现有「LocManager 定位到新点 -> .locationUpdated 通知 + 5s 节流」触发逻辑(经纬度变化驱动);上报动作从 POST /ptt/presence 改为 WS 发 { type: "presence", latitude, longitude } 文本帧。60s 常驻任务心跳继续作为保活兜底。
- WS 断开(切后台)期间不上报位置;回前台重连后由 snapshot + 首个位置帧对齐。
- PTTPresenceStream(SSE 客户端)整体被新的 WS 客户端取代。

## 接口去留

下线:
- POST /ptt/subscribe(SSE presence)
- POST /ptt/presence(位置心跳 POST)
- POST /ptt/voice(语音上传 POST)

保留:
- GET /ptt/voice/:name(APNs 兜底下载)
- POST /ptt/connect(首屏快照 / 显式 join-leave 备用通道)

新增:
- GET /ptt/ws(WebSocket,承载 presence + 语音)

## 服务端改造要点

- 依赖: 已间接引入 github.com/gorilla/websocket v1.5.3(转为直接依赖)。
- 新增 controller/PttWebSocket.go(升级 WS、读写循环、hello/leave/presence/语音帧分发)。
- 新增/改造 controller/PushToTalk/hub.go: WS 连接注册表(userID -> 活跃连接),与成员表(Channels/UserChannels)解耦。
- 语音落盘 + 择一投递: 复用现有 Channels/GlobalUsers/MsgQueue/PttPush;对有活跃 WS 的成员直接写 WS,对无活跃 WS 的成员入 MsgQueue。
- 现有 SyncChannels / BroadcastUpdate / Broadcast / SubEvent 事件模型复用;把 SSE 专用的 subscribers 映射替换为 WS 连接注册表(或让 Broadcast 面向 WS 注册表)。

## 客户端改造要点

- 新增 PTTWebSocketClient(替换 PTTPresenceStream): 建连、hello、收发文本/二进制帧、指数退避重连。
- PTTManager:
  - joinConnect / levelConnect: 加入/离开时驱动成员身份 + WS 连接。
  - presence 事件应用逻辑(apply(presenceEvent:))复用,数据源换成 WS。
  - sendPresenceHeartbeat 改为 WS 文本帧发送。
  - sendVoice 改为 WS 二进制帧发送(在线时);离线/失败处理待定(见未决问题)。
  - 新增 WS 语音接收入口 -> 落盘 -> send(.startPlay(voice), remote: true)。
- SceneDelegate: sceneWillEnterForeground / sceneDidEnterBackground 挂 WS 连/断。

## 错误处理

- WS 建连失败 / 断线: 指数退避重连(复用现有 backoffSchedule)。切后台主动断开不重连。
- 语音发送: 在线走 WS;若 WS 不可用,回退策略待定(见未决问题)。
- 服务端慢消费者: 沿用现有「队列满即丢弃,靠下次 snapshot 兜底」策略。
- 幽灵成员: 只靠显式 leave;强杀残留由对方重连拉 snapshot 纠正。

## 测试

- 服务端: WS 握手鉴权、hello 注册 + snapshot、presence 广播、语音帧解析 + 择一投递(有/无活跃 WS 两条分支)、显式 leave 广播、并发订阅者广播不阻塞。
- 客户端: 前后台连断、重连拉 snapshot、位置变化上报、WS 语音接收落盘并播放、与 APNs 入口行为一致性。
- 端到端: 双端在线走 WS;一端后台走 APNs;切换过程无重复播放。

## 未决问题(实现阶段确认)

1. 在线时 WS 语音发送失败(帧写入错误 / 连接刚断),是否回退到一次性 HTTP 上传或直接标记 AudioMessage.failed?当前倾向: 标记 failed,由用户重发(与现有失败处理一致)。
2. POST /ptt/voice(POST 上传)彻底下线后,发送方自身的本地 AudioMessage 落盘与已读状态是否有依赖需要调整。
