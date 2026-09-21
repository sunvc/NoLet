# NoLet 电脑快传（局域网）接收端

手机端在「设置 → 更多设置 → 电脑快传」开启**局域网共享**后，每次打开 App
会把剪贴板文本用 AES-256-GCM 加密后 UDP 广播到当前 Wi-Fi，无需配对、无需连接。
本程序在 Mac 上持续监听，收齐并解密后自动写入系统剪贴板，并弹一条系统通知。

## 协议要点

- 端口：UDP `39876`；目标 `255.255.255.255` + 子网定向广播
- 报文：JSON（`m/v/id/ts/dev/n/i/iv/d`），每片独立 GCM 加密
- 密钥：`SHA256(6位接收码)`，nonce 每片随机 12 字节，tag 16 字节
- 长文本自动分片（单片 700 字节，最多 32 片 ≈ 22 KB），整组重复广播 3 轮抗丢包
- Mac 端按 `id + 分片下标` 去重重组；已完成的消息 5 分钟内忽略重复投递

## 编译

需要 macOS 自带 Swift 工具链（`xcode-select --install` 一次即可）：

```bash
cd tools/mac-lan-receiver
swiftc -O NoLetLanReceiver.swift -o NoLetLanReceiver \
  -framework AppKit -framework Network -framework CryptoKit
```

## 运行

方式一：命令行直接传接收码（手机设置页可复制）：

```bash
./NoLetLanReceiver 123456
```

方式二：写入配置文件后无参运行：

```bash
echo -n 123456 > ~/.nolet-lan-code
./NoLetLanReceiver
```

首次运行 macOS 会弹防火墙提示，选**允许**接收入站连接。终端需要通知权限时
在「系统设置 → 通知」中允许终端/后台任务通知；即使不允许通知，剪贴板仍会更新。

保持窗口开着即可；手机与电脑必须在同一局域网（访客 Wi-Fi、AP 隔离、
公司网络可能屏蔽广播包）。

## 开机自启（可选）

复制编译产物并注册 launchd 服务（按实际路径调整 plist 中的二进制位置）：

```bash
mkdir -p ~/bin ~/Library/LaunchAgents
cp NoLetLanReceiver ~/bin/
echo -n 123456 > ~/.nolet-lan-code
cp com.nolet.lan-receiver.plist ~/Library/LaunchAgents/
launchctl load ~/Library/LaunchAgents/com.nolet.lan-receiver.plist
```

查看日志：

```bash
tail -f ~/Library/Logs/nolet-lan-receiver.log
```

更换接收码：改 `~/.nolet-lan-code` 后
`launchctl kickstart -k gui/$(id -u)/com.nolet.lan-receiver`。
