# PTT WebSocket 模式 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 把 PTT 的 presence 与语音收发从 SSE + APNs 迁移到一条 WebSocket(前台实时),APNs 退化为接收方无活跃 WS 时的后台兜底。

**Architecture:** 服务端新增 /ptt/ws,复用现有 Channels/UserChannels 成员模型与 SubEvent 事件体系,新增 WS 连接注册表(userID -> 活跃连接)并把 Broadcast 面向 WS;成员身份由显式 join/leave 维护,与 WS 断连解耦;语音整段 Opus 走 WS 二进制单帧,服务端按接收者是否有活跃 WS 择一投递(WS 直推 / 否则入 MsgQueue 走 APNs)。客户端用 PTTWebSocketClient 取代 PTTPresenceStream(SSE),前台连、后台断。

**Tech Stack:** Go 1.25.5 + gin + gorilla/websocket v1.5.3;iOS Swift 6 + URLSessionWebSocketTask + Opus + PushToTalk framework + Defaults + GRDB。

## Global Constraints

- 服务端 module: github.com/sunvc/NoLets, go 1.25.5。
- WS 依赖: github.com/gorilla/websocket v1.5.3(已在 go.sum,需从 indirect 提为直接依赖)。
- WS 路由: GET /ptt/ws,挂在 `if common.LocalConfig.System.Voice` 的 ptt group 下,经现有 Verification() 全局中间件。
- 鉴权头复用 CryptoManager.signature: X-Device / X-USER / Authorization / X-Signature。
- 语音文件命名保持现有格式: hex(channel)-userID-base32(ms).opus;签名前缀由 X-PFA 头的 "1-"/"0-" 迁移到帧元数据 sign 字段。
- 语音落盘目录保持 data/voices/(供 GET /ptt/voice/:name 兜底下载)。
- 保留接口: GET /ptt/voice/:name、POST /ptt/connect。下线: POST /ptt/subscribe、POST /ptt/presence、POST /ptt/voice(POST 分支)。
- 在线判定 = 是否在频道(成员表),不等于 WS 是否连接。频道退出只靠显式 leave,不设 TTL。
- 提交策略: 每个 Task 末尾提交;若 GPG 签名在无终端环境失败,使用 git commit --no-gpg-sign。
- 测试现状: 两仓库均无既有测试目标。服务端纯逻辑用 Go table-driven test(go test);iOS 侧硬件/框架强耦合,用 xcodebuild 编译验证 + 手动集成清单,不强行引入 XCTest 目标。
- iOS 编译验证命令: `xcodebuild -scheme NoLet -project NoLet.xcodeproj -destination 'generic/platform=iOS' build`(仅验证编译,不签名运行)。

---

## Task 1: 语音二进制帧编解码 (服务端)

**Files:**
- Create: `controller/PushToTalk/frame.go`
- Test: `controller/PushToTalk/frame_test.go`

**Interfaces:**
- Produces:
  - `type VoiceFrameMeta struct { Channel string; File string; Sign bool; Sender string }` (json tags: channel/file/sign/sender)
  - `func EncodeVoiceFrame(meta VoiceFrameMeta, audio []byte) ([]byte, error)`
  - `func DecodeVoiceFrame(frame []byte) (VoiceFrameMeta, []byte, error)`
- 帧格式: 4 字节大端 uint32 元数据长度 N + N 字节元数据 JSON + 剩余音频字节。

- [ ] **Step 1: Write the failing test**

```go
package PushToTalk

import (
	"bytes"
	"testing"
)

func TestVoiceFrameRoundTrip(t *testing.T) {
	meta := VoiceFrameMeta{Channel: "30v", File: "30v-uid-abc.opus", Sign: true, Sender: "uid"}
	audio := []byte{0x01, 0x02, 0x03, 0x04}
	frame, err := EncodeVoiceFrame(meta, audio)
	if err != nil {
		t.Fatalf("encode: %v", err)
	}
	gotMeta, gotAudio, err := DecodeVoiceFrame(frame)
	if err != nil {
		t.Fatalf("decode: %v", err)
	}
	if gotMeta != meta {
		t.Fatalf("meta mismatch: got %+v want %+v", gotMeta, meta)
	}
	if !bytes.Equal(gotAudio, audio) {
		t.Fatalf("audio mismatch: got %v want %v", gotAudio, audio)
	}
}

func TestDecodeVoiceFrameTruncated(t *testing.T) {
	if _, _, err := DecodeVoiceFrame([]byte{0x00, 0x00}); err == nil {
		t.Fatal("expected error on short frame")
	}
	if _, _, err := DecodeVoiceFrame([]byte{0x00, 0x00, 0x00, 0x10, 0x7b}); err == nil {
		t.Fatal("expected error when meta length exceeds buffer")
	}
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `go test ./controller/PushToTalk/ -run TestVoiceFrame -v`
Expected: FAIL (undefined: VoiceFrameMeta / EncodeVoiceFrame / DecodeVoiceFrame)

- [ ] **Step 3: Write minimal implementation**

```go
package PushToTalk

import (
	"encoding/binary"
	"encoding/json"
	"errors"
)

// VoiceFrameMeta 是语音二进制帧头部的元数据。
type VoiceFrameMeta struct {
	Channel string `json:"channel"`
	File    string `json:"file"`
	Sign    bool   `json:"sign"`
	Sender  string `json:"sender"`
}

// EncodeVoiceFrame 组装 [4字节大端元数据长度][元数据JSON][音频] 单帧。
func EncodeVoiceFrame(meta VoiceFrameMeta, audio []byte) ([]byte, error) {
	metaBytes, err := json.Marshal(meta)
	if err != nil {
		return nil, err
	}
	out := make([]byte, 4+len(metaBytes)+len(audio))
	binary.BigEndian.PutUint32(out[0:4], uint32(len(metaBytes)))
	copy(out[4:], metaBytes)
	copy(out[4+len(metaBytes):], audio)
	return out, nil
}

// DecodeVoiceFrame 解析单帧,返回元数据与音频切片。
func DecodeVoiceFrame(frame []byte) (VoiceFrameMeta, []byte, error) {
	var meta VoiceFrameMeta
	if len(frame) < 4 {
		return meta, nil, errors.New("frame too short")
	}
	n := binary.BigEndian.Uint32(frame[0:4])
	if int(n) > len(frame)-4 {
		return meta, nil, errors.New("meta length exceeds frame")
	}
	if err := json.Unmarshal(frame[4:4+n], &meta); err != nil {
		return meta, nil, err
	}
	audio := frame[4+n:]
	return meta, audio, nil
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `go test ./controller/PushToTalk/ -run TestVoiceFrame -v`
Expected: PASS (both tests)

- [ ] **Step 5: Commit**

```bash
git add controller/PushToTalk/frame.go controller/PushToTalk/frame_test.go
git commit --no-gpg-sign -m "feat(ptt): voice binary frame codec"
```

---

## Task 2: WS 连接注册表 (服务端 hub)

**Files:**
- Create: `controller/PushToTalk/hub.go`
- Test: `controller/PushToTalk/hub_test.go`

**Interfaces:**
- Consumes: 无(独立注册表,靠 Task 4 的 handler 调用)。
- Produces:
  - `type Conn interface { WriteText(b []byte) error; WriteBinary(b []byte) error }`
  - `func RegisterConn(userID string, c Conn)`  // 覆盖同一 userID 的旧连接(以新连接为活跃)
  - `func UnregisterConn(userID string, c Conn)` // 仅当当前活跃连接 == c 时才移除,避免竞态误删
  - `func HasActiveConn(userID string) bool`
  - `func SendText(userID string, b []byte) bool`   // 无活跃连接返回 false
  - `func SendBinary(userID string, b []byte) bool` // 无活跃连接返回 false

- [ ] **Step 1: Write the failing test**

```go
package PushToTalk

import (
	"sync"
	"testing"
)

type fakeConn struct {
	mu     sync.Mutex
	text   [][]byte
	binary [][]byte
}

func (f *fakeConn) WriteText(b []byte) error {
	f.mu.Lock()
	defer f.mu.Unlock()
	f.text = append(f.text, append([]byte(nil), b...))
	return nil
}

func (f *fakeConn) WriteBinary(b []byte) error {
	f.mu.Lock()
	defer f.mu.Unlock()
	f.binary = append(f.binary, append([]byte(nil), b...))
	return nil
}

func TestHubRegisterSendUnregister(t *testing.T) {
	c := &fakeConn{}
	RegisterConn("u1", c)
	if !HasActiveConn("u1") {
		t.Fatal("expected active conn for u1")
	}
	if HasActiveConn("nobody") {
		t.Fatal("did not expect active conn for nobody")
	}
	if !SendBinary("u1", []byte{9}) {
		t.Fatal("SendBinary should succeed for active conn")
	}
	if SendText("nobody", []byte("x")) {
		t.Fatal("SendText should fail for missing conn")
	}
	UnregisterConn("u1", c)
	if HasActiveConn("u1") {
		t.Fatal("expected u1 removed after unregister")
	}
}

func TestHubUnregisterStaleConnKeepsNew(t *testing.T) {
	old := &fakeConn{}
	fresh := &fakeConn{}
	RegisterConn("u2", old)
	RegisterConn("u2", fresh) // fresh 成为活跃连接
	UnregisterConn("u2", old) // 旧连接晚到的清理不应移除 fresh
	if !HasActiveConn("u2") {
		t.Fatal("fresh conn must survive stale unregister")
	}
	UnregisterConn("u2", fresh)
	if HasActiveConn("u2") {
		t.Fatal("expected u2 removed")
	}
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `go test ./controller/PushToTalk/ -run TestHub -v`
Expected: FAIL (undefined: RegisterConn / HasActiveConn / ...)

- [ ] **Step 3: Write minimal implementation**

```go
package PushToTalk

import "sync"

// Conn 抽象一个可写的 WS 连接,便于测试注入 fake。
type Conn interface {
	WriteText(b []byte) error
	WriteBinary(b []byte) error
}

var (
	wsConns   = make(map[string]Conn) // userID -> 当前活跃连接
	wsConnsMu sync.RWMutex
)

// RegisterConn 把 userID 的活跃连接设为 c(覆盖旧连接)。
func RegisterConn(userID string, c Conn) {
	wsConnsMu.Lock()
	wsConns[userID] = c
	wsConnsMu.Unlock()
}

// UnregisterConn 仅当当前活跃连接就是 c 时移除,避免重连竞态误删新连接。
func UnregisterConn(userID string, c Conn) {
	wsConnsMu.Lock()
	if cur, ok := wsConns[userID]; ok && cur == c {
		delete(wsConns, userID)
	}
	wsConnsMu.Unlock()
}

// HasActiveConn 报告 userID 当前是否有活跃 WS。
func HasActiveConn(userID string) bool {
	wsConnsMu.RLock()
	_, ok := wsConns[userID]
	wsConnsMu.RUnlock()
	return ok
}

// SendText 向 userID 的活跃连接写文本帧,无连接返回 false。
func SendText(userID string, b []byte) bool {
	wsConnsMu.RLock()
	c, ok := wsConns[userID]
	wsConnsMu.RUnlock()
	if !ok {
		return false
	}
	return c.WriteText(b) == nil
}

// SendBinary 向 userID 的活跃连接写二进制帧,无连接返回 false。
func SendBinary(userID string, b []byte) bool {
	wsConnsMu.RLock()
	c, ok := wsConns[userID]
	wsConnsMu.RUnlock()
	if !ok {
		return false
	}
	return c.WriteBinary(b) == nil
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `go test ./controller/PushToTalk/ -run TestHub -v`
Expected: PASS (both tests)

- [ ] **Step 5: Commit**

```bash
git add controller/PushToTalk/hub.go controller/PushToTalk/hub_test.go
git commit --no-gpg-sign -m "feat(ptt): websocket connection registry"
```

---

## Task 3: 语音择一投递 (服务端 fan-out)

**Files:**
- Create: `controller/PushToTalk/deliver.go`
- Test: `controller/PushToTalk/deliver_test.go`

**Interfaces:**
- Consumes: `Channels`/`GlobalUsers`/`PushTaskQueue`(main.go)、`PushTask`/`VoiceMessage`(models.go)、`HasActiveConn`/`SendBinary`(Task 2)、`EncodeVoiceFrame`/`VoiceFrameMeta`(Task 1)。
- Produces:
  - `func DeliverVoice(msg VoiceMessage, audio []byte)`  // 对频道成员(排除 sender)择一投递: 有活跃 WS 直推二进制帧;否则生成 PushTask 入 PushTaskQueue 走 APNs。

**Note:** DeliverVoice 需要 sender/channel 与在线成员比对。为可测,把纯选择逻辑抽成内部函数 `planVoiceTargets`,只依赖入参不依赖全局。

- [ ] **Step 1: Write the failing test**

```go
package PushToTalk

import (
	"sort"
	"testing"
)

func TestPlanVoiceTargets(t *testing.T) {
	members := []string{"sender", "wsUser", "apnsUser", "wsUser2"}
	hasWS := map[string]bool{"wsUser": true, "wsUser2": true}
	ws, apns := planVoiceTargets("sender", members, func(id string) bool { return hasWS[id] })
	sort.Strings(ws)
	sort.Strings(apns)
	if len(ws) != 2 || ws[0] != "wsUser" || ws[1] != "wsUser2" {
		t.Fatalf("ws targets wrong: %v", ws)
	}
	if len(apns) != 1 || apns[0] != "apnsUser" {
		t.Fatalf("apns targets wrong: %v", apns)
	}
}

func TestPlanVoiceTargetsExcludesSender(t *testing.T) {
	members := []string{"sender"}
	ws, apns := planVoiceTargets("sender", members, func(string) bool { return true })
	if len(ws) != 0 || len(apns) != 0 {
		t.Fatalf("sender must be excluded: ws=%v apns=%v", ws, apns)
	}
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `go test ./controller/PushToTalk/ -run TestPlanVoiceTargets -v`
Expected: FAIL (undefined: planVoiceTargets)

- [ ] **Step 3: Write minimal implementation**

```go
package PushToTalk

// planVoiceTargets 把频道成员分成"走 WS"和"走 APNs"两组,排除 sender。
// hasWS 注入便于测试;生产传 HasActiveConn。
func planVoiceTargets(sender string, members []string, hasWS func(string) bool) (ws, apns []string) {
	for _, id := range members {
		if id == sender {
			continue
		}
		if hasWS(id) {
			ws = append(ws, id)
		} else {
			apns = append(apns, id)
		}
	}
	return ws, apns
}

// DeliverVoice 落盘之后调用: 对频道其他成员择一投递语音。
func DeliverVoice(msg VoiceMessage, audio []byte) {
	ChannelLock.RLock()
	ch, ok := Channels[msg.Channel]
	if !ok {
		ChannelLock.RUnlock()
		return
	}
	members := make([]string, 0, len(ch.UserIDs))
	for uid := range ch.UserIDs {
		members = append(members, uid)
	}
	ChannelLock.RUnlock()

	wsTargets, apnsTargets := planVoiceTargets(msg.Sender, members, HasActiveConn)

	// sign 从文件名前缀推断: fileName 形如 "1-<hz>-<id>-<ts>.opus" 或 "0-..."。
	meta := VoiceFrameMeta{
		Channel: msg.Channel,
		File:    msg.FileName,
		Sign:    len(msg.FileName) > 0 && msg.FileName[0] == '1',
		Sender:  msg.Sender,
	}
	frame, err := EncodeVoiceFrame(meta, audio)
	if err == nil {
		for _, id := range wsTargets {
			if !SendBinary(id, frame) {
				// 刚断开: 兜底转 APNs
				apnsTargets = append(apnsTargets, id)
			}
		}
	} else {
		apnsTargets = append(apnsTargets, wsTargets...)
	}

	if len(apnsTargets) == 0 {
		return
	}
	// 直接对 apnsTargets 生成 PushTask 入第二级队列,避免走 startPttConsumer
	// 再次全频道 fan-out(那样会给已收到 WS 帧的成员重复投递)。
	url := msg.Host + "/ptt/voice/" + msg.FileName
	for _, id := range apnsTargets {
		val, ok := GlobalUsers.Load(id)
		if !ok {
			continue
		}
		u, ok := val.(PttUser)
		if !ok || u.Token == "" {
			continue
		}
		select {
		case PushTaskQueue <- PushTask{Token: u.Token, Url: url}:
		default:
		}
	}
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `go test ./controller/PushToTalk/ -run TestPlanVoiceTargets -v`
Expected: PASS (both tests)

- [ ] **Step 5: Commit**

```bash
git add controller/PushToTalk/deliver.go controller/PushToTalk/deliver_test.go
git commit --no-gpg-sign -m "feat(ptt): pick-one voice delivery (ws vs apns)"
```

---

## Task 4: WS handler + 路由接线 (服务端)

**Files:**
- Create: `controller/PttWebSocket.go`
- Modify: `router/router.go`(ptt group 增加 `ptt.GET("/ws", controller.PttWebSocket)`;删除 subscribe/presence/POST-voice 路由)
- Modify: `go.mod`(gorilla/websocket 从 indirect 提为直接依赖)

**Interfaces:**
- Consumes: `PushToTalk2.SyncChannels`/`BroadcastUpdate`/`Channels`/`ChannelLock`/`SubEvent`/`EventSnapshot`/`MarshalEvent`/`PttUser`/`JoinParams`/`PttUserResp`/`UserListResp`(现有);`RegisterConn`/`UnregisterConn`(Task 2);`DecodeVoiceFrame`/`VoiceFrameMeta`(Task 1);`DeliverVoice`(Task 3)。
- Produces: `func PttWebSocket(c *gin.Context)`;类型 `wsConn`(实现 `PushToTalk2.Conn`,对 `*websocket.Conn` 加写锁)。

本任务以编译 + go vet + 手动联调验证(WS 属 I/O 集成,不做单测)。核心逻辑已被 Task 1-3 的单测覆盖。

- [ ] **Step 1: 提升 gorilla/websocket 为直接依赖**

Run: `go get github.com/gorilla/websocket@v1.5.3`
Expected: go.mod 中该行去掉 `// indirect`。

- [ ] **Step 2: 写 handler**

创建 `controller/PttWebSocket.go`:

```go
package controller

import (
	"encoding/json"
	"net/http"
	"os"
	"path/filepath"
	"sync"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/gorilla/websocket"
	PushToTalk2 "github.com/sunvc/NoLets/controller/PushToTalk"
)

var wsUpgrader = websocket.Upgrader{
	ReadBufferSize:  4096,
	WriteBufferSize: 4096,
	CheckOrigin:     func(r *http.Request) bool { return true },
}

// wsConn 给 *websocket.Conn 加写锁,满足 PushToTalk2.Conn 接口。
type wsConn struct {
	mu   sync.Mutex
	conn *websocket.Conn
}

func (w *wsConn) WriteText(b []byte) error {
	w.mu.Lock()
	defer w.mu.Unlock()
	return w.conn.WriteMessage(websocket.TextMessage, b)
}

func (w *wsConn) WriteBinary(b []byte) error {
	w.mu.Lock()
	defer w.mu.Unlock()
	return w.conn.WriteMessage(websocket.BinaryMessage, b)
}

// 客户端文本控制消息。type 空视为 hello(首帧)。
type wsClientMsg struct {
	Type      string   `json:"type"`
	ID        string   `json:"id"`
	Channels  []string `json:"channels"`
	Latitude  float64  `json:"latitude"`
	Longitude float64  `json:"longitude"`
	Token     string   `json:"token"`
	Host      string   `json:"host"`
}

func PttWebSocket(c *gin.Context) {
	conn, err := wsUpgrader.Upgrade(c.Writer, c.Request, nil)
	if err != nil {
		return
	}
	wc := &wsConn{conn: conn}

	var (
		user     PushToTalk2.PttUser
		channels []string
		joined   bool
	)

	conn.SetReadLimit(2 << 20) // 2MB,整段 Opus 足够
	_ = conn.SetReadDeadline(time.Now().Add(90 * time.Second))
	conn.SetPongHandler(func(string) error {
		return conn.SetReadDeadline(time.Now().Add(90 * time.Second))
	})

	// 服务端 ping 保活
	stopPing := make(chan struct{})
	go func() {
		t := time.NewTicker(30 * time.Second)
		defer t.Stop()
		for {
			select {
			case <-stopPing:
				return
			case <-t.C:
				wc.mu.Lock()
				_ = conn.WriteMessage(websocket.PingMessage, nil)
				wc.mu.Unlock()
			}
		}
	}()

	defer func() {
		close(stopPing)
		if joined {
			PushToTalk2.UnregisterConn(user.ID, wc)
			// 显式 leave 未收到(断线)时不移除成员身份: 只解绑连接。
		}
		_ = conn.Close()
	}()

	for {
		mt, data, err := conn.ReadMessage()
		if err != nil {
			return
		}
		_ = conn.SetReadDeadline(time.Now().Add(90 * time.Second))

		switch mt {
		case websocket.TextMessage:
			var m wsClientMsg
			if json.Unmarshal(data, &m) != nil {
				continue
			}
			switch m.Type {
			case "", "hello":
				user = PushToTalk2.PttUser{
					ID: m.ID, Latitude: m.Latitude, Longitude: m.Longitude,
					Token: m.Token, Host: m.Host, Timestamp: time.Now().UnixMilli(),
				}
				channels = m.Channels
				if user.ID == "" || len(channels) == 0 {
					return
				}
				PushToTalk2.RegisterConn(user.ID, wc)
				PushToTalk2.SyncChannels(user, channels)
				joined = true
				sendSnapshots(wc, channels)
			case "presence":
				if !joined {
					continue
				}
				user.Latitude = m.Latitude
				user.Longitude = m.Longitude
				user.Timestamp = time.Now().UnixMilli()
				PushToTalk2.BroadcastUpdate(user)
			case "leave":
				if joined {
					PushToTalk2.SyncChannels(user, []string{})
					PushToTalk2.UnregisterConn(user.ID, wc)
					joined = false
				}
				return
			}
		case websocket.BinaryMessage:
			if !joined {
				continue
			}
			handleVoiceFrame(c, user.ID, data)
		}
	}
}

func sendSnapshots(wc *wsConn, channels []string) {
	nowMs := time.Now().UnixMilli()
	PushToTalk2.ChannelLock.RLock()
	defer PushToTalk2.ChannelLock.RUnlock()
	for _, chName := range channels {
		users := []PushToTalk2.PttUserResp{}
		if ch, ok := PushToTalk2.Channels[chName]; ok {
			users = ch.UserListResp()
		}
		snap := PushToTalk2.SubEvent{
			Event:   PushToTalk2.EventSnapshot,
			Channel: chName,
			Users:   users,
			Ts:      nowMs,
		}
		_ = wc.WriteText(PushToTalk2.MarshalEvent(snap))
	}
}

// handleVoiceFrame 解帧 -> 落盘 -> DeliverVoice 择一投递。
func handleVoiceFrame(c *gin.Context, senderID string, data []byte) {
	meta, audio, err := PushToTalk2.DecodeVoiceFrame(data)
	if err != nil || meta.File == "" {
		return
	}
	savePath := filepath.Join("data", "voices", meta.File)
	if err := os.WriteFile(savePath, audio, 0644); err != nil {
		return
	}
	msg := PushToTalk2.VoiceMessage{
		ID:        uuid.New().String(),
		Host:      GetAbsoluteHost(c),
		Channel:   meta.Channel,
		FileName:  meta.File,
		Sender:    senderID,
		CreatedAt: time.Now().UnixMilli(),
	}
	PushToTalk2.DeliverVoice(msg, audio)
}
```

实现说明: 上面的 import 列表要相应精简——移除未使用的 `io` 与 `common`(除非实现时另有引用)。`data/voices/` 目录复用现有约定,与 GET /ptt/voice/:name 一致。

- [ ] **Step 3: 改路由**

修改 `router/router.go` 的 ptt group:

```go
ptt := router.Group("/ptt")
ptt.POST("connect", controller.PttConnect)
ptt.GET("/voice/:name", controller.PttVoice)
ptt.GET("/ws", controller.PttWebSocket)
```

删除 `ptt.POST("/voice", ...)`、`ptt.POST("/subscribe", ...)`、`ptt.POST("/presence", ...)` 三行。

- [ ] **Step 4: 编译 + vet**

Run: `go build ./... && go vet ./...`
Expected: 通过。若报 PttVoice 的 POST 分支变成死代码,不影响编译(下一 Task 清理);若报未使用引用,按实现说明删除。

- [ ] **Step 5: Commit**

```bash
git add controller/PttWebSocket.go router/router.go go.mod go.sum
git commit --no-gpg-sign -m "feat(ptt): websocket handler and routing"
```

---

## Task 5: 清理下线的 SSE / POST 接口 (服务端)

**Files:**
- Delete: `controller/PttSubscribe.go`
- Delete: `controller/PttPresence.go`
- Modify: `controller/PushToTalk.go`(PttVoice 去掉 POST 分支,只留 GET)
- Modify: `controller/PushToTalk/events.go`(移除仅 SSE 使用的 subscribers/Subscribe;保留 SubEvent/Event 常量/MarshalEvent/Broadcast)

**Interfaces:**
- Broadcast 从"面向 subscribers 通道"改为"面向 WS 注册表": `func Broadcast(channelName, excludeUserID string, evt SubEvent)` 遍历该频道成员,对每个非 exclude 成员调用 `SendText(userID, MarshalEvent(evt))`。
- 保留 SubEvent / EventSnapshot 等常量供 handler 使用。

本任务以编译 + vet + 现有 go test 全绿验证。

- [ ] **Step 1: 改 Broadcast 面向 WS 注册表**

替换 `controller/PushToTalk/events.go` 中 Broadcast 及 subscribers 相关代码为:

```go
package PushToTalk

import "encoding/json"

const (
	EventSnapshot = "snapshot"
	EventJoin     = "join"
	EventLeave    = "leave"
	EventUpdate   = "update"
	EventPing     = "ping"
)

type SubEvent struct {
	Event   string        `json:"event"`
	Channel string        `json:"channel"`
	User    *PttUserResp  `json:"user,omitempty"`
	Users   []PttUserResp `json:"users,omitempty"`
	Ts      int64         `json:"ts"`
}

// Broadcast 向频道内成员(排除 excludeUserID)推送事件。
// 只推给当前有活跃 WS 的成员;无 WS 成员靠下次重连的 snapshot 兜底。
func Broadcast(channelName string, excludeUserID string, evt SubEvent) {
	ChannelLock.RLock()
	ch, ok := Channels[channelName]
	if !ok {
		ChannelLock.RUnlock()
		return
	}
	targets := make([]string, 0, len(ch.UserIDs))
	for uid := range ch.UserIDs {
		if uid == excludeUserID {
			continue
		}
		targets = append(targets, uid)
	}
	ChannelLock.RUnlock()

	payload := MarshalEvent(evt)
	for _, uid := range targets {
		SendText(uid, payload)
	}
}

func MarshalEvent(evt SubEvent) []byte {
	b, _ := json.Marshal(evt)
	return b
}
```

说明: 删除 `subscriber`/`subscribers`/`subscriberLock`/`Subscribe`/`subscriberBuffer`。

- [ ] **Step 2: 删 SSE handler 文件**

Run: `git rm controller/PttSubscribe.go controller/PttPresence.go`

- [ ] **Step 3: PttVoice 去掉 POST 分支**

修改 `controller/PushToTalk.go` 的 `PttVoice`,删除整个 `if c.Request.Method == "POST" { ... }` 段(含 getUserData/veryPttTimestamp 若不再被引用一并删除),只保留 GET 分支:

```go
func PttVoice(c *gin.Context) {
	fileName := c.Param("name")
	if fileName == "" || len(fileName) < 6 {
		c.AbortWithStatus(404)
		return
	}
	path := common.BaseDir("voices", fileName)
	if _, err := os.Stat(path); err != nil {
		c.AbortWithStatus(404)
		return
	}
	c.Header("Content-Type", "audio/ogg")
	c.File(path)
}
```

保留 `GetAbsoluteHost`(Task 4 handler 用到)。删除仅 POST 分支使用的 `getUserData`/`veryPttTimestamp` 及随之无用的 import(io/os/filepath/strconv/strings/time/uuid 按实际保留)。

- [ ] **Step 4: 编译 + vet + 测试**

Run: `go build ./... && go vet ./... && go test ./controller/PushToTalk/ -v`
Expected: 编译通过,Task 1-3 单测全绿。

- [ ] **Step 5: Commit**

```bash
git add -A
git commit --no-gpg-sign -m "refactor(ptt): drop SSE subscribe/presence and POST voice"
```

---

## Task 6: PTTWebSocketClient (iOS,取代 PTTPresenceStream)

**Files:**
- Create: `NoLet/PushToTalk/PTTManager/PTTWebSocketClient.swift`
- Delete: `NoLet/PushToTalk/PTTManager/PTTPresenceStream.swift`(在 Task 7 接线后删除;本任务先新增)
- Modify: `NoLet.xcodeproj/project.pbxproj`(新增文件加入 NoLet target;删除文件时移除引用)

**Interfaces:**
- 复用现有 `PresenceEvent`(定义在 PTTPresenceStream.swift;删除该文件时把 PresenceEvent 定义搬到本文件顶部,保持结构不变)。
- Produces:
  - `protocol PTTWebSocketClientDelegate: AnyObject, Sendable`
    - `func webSocket(_ client: PTTWebSocketClient, didReceive event: PresenceEvent)`
    - `func webSocket(_ client: PTTWebSocketClient, didReceiveVoice meta: PTTVoiceMeta, audio: Data)`
    - `func webSocket(_ client: PTTWebSocketClient, didChangeConnected connected: Bool)`
  - `struct PTTVoiceMeta: Decodable, Sendable { let channel: String; let file: String; let sign: Bool; let sender: String }`
  - `final class PTTWebSocketClient`:
    - `func start(channel: PTTChannel)`  // 建连 + 发 hello,幂等
    - `func stop()`                      // 主动断开(切后台/关频道)
    - `func sendLeave()`                 // 发 LeaveMsg 文本帧,然后 stop()
    - `func sendPresence(latitude: Double, longitude: Double)`  // 文本帧
    - `func sendVoice(meta: PTTVoiceMeta, audio: Data) -> Bool`  // 二进制帧,返回是否成功写入
    - `weak var delegate: PTTWebSocketClientDelegate?`

**Design:** 用 `URLSessionWebSocketTask`。连接 `GET {server.url}/ptt/ws`(带鉴权头),打开后立即发 hello 文本帧。用一个接收循环 `receive` 递归读取,文本帧解析为 PresenceEvent(复用现有 JSON 结构),二进制帧按 `[4字节大端长度][meta JSON][audio]` 拆包回调。指数退避重连复用 `backoffSchedule`。切后台调用 stop 后不再重连。

二进制帧封装(客户端发送,与服务端 DecodeVoiceFrame 对齐):

```swift
private func encodeVoiceFrame(meta: PTTVoiceMeta, audio: Data) -> Data? {
    guard let metaData = try? JSONEncoder().encode(meta) else { return nil }
    var out = Data()
    var len = UInt32(metaData.count).bigEndian
    withUnsafeBytes(of: &len) { out.append(contentsOf: $0) }
    out.append(metaData)
    out.append(audio)
    return out
}

private func decodeVoiceFrame(_ data: Data) -> (PTTVoiceMeta, Data)? {
    guard data.count >= 4 else { return nil }
    let n = Int(data.subdata(in: 0..<4).withUnsafeBytes { $0.load(as: UInt32.self).bigEndian })
    guard n >= 0, 4 + n <= data.count else { return nil }
    let metaData = data.subdata(in: 4..<(4 + n))
    let audio = data.subdata(in: (4 + n)..<data.count)
    guard let meta = try? JSONDecoder().decode(PTTVoiceMeta.self, from: metaData) else { return nil }
    return (meta, audio)
}
```

`PTTVoiceMeta` 需同时是 Encodable(发送)与 Decodable(接收),声明为 `Codable`。

hello / presence 文本帧:

```swift
struct Hello: Encodable {
    let type = "hello"
    let id: String
    let channels: [String]
    let latitude: Double
    let longitude: Double
    let token: String
    let host: String
}
struct PresenceMsg: Encodable {
    let type = "presence"
    let latitude: Double
    let longitude: Double
}
struct LeaveMsg: Encodable { let type = "leave" }
```

- [ ] **Step 1: 参照 PTTPresenceStream 写 PTTWebSocketClient**

以 PTTPresenceStream.swift 的连接/重连骨架为蓝本(backoffSchedule、start/stop、currentChannel 幂等判断、MainActor 取 Body 与鉴权头),把传输从 `URLSession.bytes(for:)` SSE 行解析换成 `URLSessionWebSocketTask`:
- `start(channel:)` 建 task、`resume()`、发 hello、进 receive 循环。
- receive 循环: `.string` -> 尝试解析 PresenceEvent 回调 didReceive;`.data` -> decodeVoiceFrame 回调 didReceiveVoice。
- 断开/错误 -> didChangeConnected(false) -> 退避重连(除非已 stop)。
- `sendVoice` 用 `task.send(.data(frame))`,`sendPresence` 用 `task.send(.string(json))`。

按 interfaces 段的签名实现,不新增其它 public 方法。

- [ ] **Step 2: 把新文件加入 NoLet target**

在 Xcode 里将 `PTTWebSocketClient.swift` 加入 NoLet target(或手动编辑 project.pbxproj 增加 PBXBuildFile/PBXFileReference/Sources 引用)。

- [ ] **Step 3: 编译验证**

Run: `xcodebuild -scheme NoLet -project NoLet.xcodeproj -destination 'generic/platform=iOS' build`
Expected: 编译通过(此时 PTTWebSocketClient 尚未被使用,允许 unused 警告)。

- [ ] **Step 4: Commit**

```bash
git add NoLet/PushToTalk/PTTManager/PTTWebSocketClient.swift NoLet.xcodeproj/project.pbxproj
git commit --no-gpg-sign -m "feat(ptt): add PTTWebSocketClient"
```

---

## Task 7: PTTManager 接线到 WebSocket (iOS)

**Files:**
- Modify: `NoLet/PushToTalk/PTTManager.swift`
- Delete: `NoLet/PushToTalk/PTTManager/PTTPresenceStream.swift`(把 PresenceEvent 已在 Task 6 搬走)
- Modify: `NoLet.xcodeproj/project.pbxproj`(移除 PTTPresenceStream 引用)

**Interfaces:**
- Consumes: `PTTWebSocketClient`(Task 6)。
- Replaces: `private let presence = PTTPresenceStream()` -> `private let wsClient = PTTWebSocketClient()`。
- PTTManager 实现 `PTTWebSocketClientDelegate` 取代 `PTTPresenceStreamDelegate`。

- [ ] **Step 1: 替换 presence 成员与 delegate**

- 把 `private let presence = PTTPresenceStream()` 改为 `private let wsClient = PTTWebSocketClient()`,init 里 `self.wsClient.delegate = self`。
- `extension PTTManager: PTTPresenceStreamDelegate` 改为 `extension PTTManager: PTTWebSocketClientDelegate`:
  - `didReceive event:` -> 复用现有 `apply(presenceEvent:)`(签名不变,PresenceEvent 结构不变)。
  - `didChangeConnected:` -> 复用现有逻辑(设置 serverStatus)。
  - 新增 `didReceiveVoice meta:audio:`:

```swift
nonisolated func webSocket(
    _ client: PTTWebSocketClient,
    didReceiveVoice meta: PTTVoiceMeta,
    audio: Data
) {
    Task {
        if let voice = await self.saveVoice(fromWS: meta, audio: audio) {
            await self.send(.startPlay(voice), remote: true)
        }
    }
}
```

- [ ] **Step 2: 新增 saveVoice(fromWS:audio:)**

在 PTTManager 语音相关 extension 增加(与现有 `saveVoice(remoteUrl:)` 并列,复用解密与落盘):

```swift
func saveVoice(fromWS meta: PTTVoiceMeta, audio: Data) async -> AudioMessage? {
    do {
        guard let filePath = NCONFIG.getDir(.ptt)?.appendingPathComponent(meta.file) else {
            return nil
        }
        var data = audio
        if meta.sign {
            guard let decoded = CryptoModelConfig.data.decrypt(inputData: data) else {
                throw NoletError(message: "decrypt error")
            }
            data = decoded
        }
        try data.write(to: filePath)
        let voice = AudioMessage(
            channel: meta.channel,
            from: meta.sender,
            file: meta.file,
            read: false,
            sign: meta.sign,
            status: .success
        )
        try await AudioMessageDBManager.shared.save(voice)
        return voice
    } catch {
        logger.error("saveVoice(fromWS): \(error.localizedDescription)")
        return nil
    }
}
```

注意: `AudioMessage` 初始化参数按其定义补齐(id/timestamp 有默认值)。file 直接用 meta.file(不含服务器 host)。

- [ ] **Step 3: presence 心跳走 WS**

- `sendPresenceHeartbeat()` 改为: 若频道 OK,调用 `wsClient.sendPresence(latitude:longitude:)` 用当前坐标;不再发 `/ptt/presence` POST。保留节流/60s 兜底调用点不变(它们改成调用 sendPresence)。
- `joinConnect()`: 把 `self.presence.start(channel:)` 改为 `self.wsClient.start(channel:)`。
- `levelConnect()`: 把 `self.presence.stop()` 改为 `self.wsClient.stop()`,并在此前发送 leave: `wsClient.sendLeave()`(若实现了)或直接 stop 让服务端靠显式 leave——按决策"只靠显式离开",levelConnect 是显式关闭频道,应发 leave。为此在 Task 6 的 PTTWebSocketClient 增补 `func sendLeave()`(发 LeaveMsg 文本帧后再 stop)。
- `publicJoinConnect()` 结尾的 `self.presence.start(...)` 同样改为 `wsClient.start(...)`。

- [ ] **Step 4: sendVoice 走 WS(在线),失败标记 failed**

修改 `sendVoice(message:)`: 保留现有读文件 + 加密逻辑,把"HTTP uploadFile"替换为:

```swift
let meta = PTTVoiceMeta(
    channel: channel.hex(),
    file: message.file,
    sign: pttSignature,
    sender: Defaults[.member].id
)
let ok = wsClient.sendVoice(meta: meta, audio: data)
self.setStatus(message: message, status: ok ? .success : .failed)
if !ok {
    Toast.error(title: "发送语音失败")
}
```

未决问题 1 决议: WS 不可用直接标 failed,由用户重发,不回退 HTTP。未决问题 2: 发送方本地 AudioMessage 落盘在 `saveVoice(data:)` 中已完成,不依赖 POST /ptt/voice,无需调整。

- [ ] **Step 5: 删除 PTTPresenceStream.swift + 清 target 引用**

Run: `git rm NoLet/PushToTalk/PTTManager/PTTPresenceStream.swift`
并在 project.pbxproj 移除其 build/file 引用(确保 PresenceEvent 已搬到 PTTWebSocketClient.swift)。

- [ ] **Step 6: 编译验证**

Run: `xcodebuild -scheme NoLet -project NoLet.xcodeproj -destination 'generic/platform=iOS' build`
Expected: 编译通过,无对 PTTPresenceStream 的残留引用。

- [ ] **Step 7: Commit**

```bash
git add -A
git commit --no-gpg-sign -m "feat(ptt): wire PTTManager to websocket transport"
```

---

## Task 8: 前后台连断 (iOS SceneDelegate)

**Files:**
- Modify: `NoLet/SceneDelegate.swift`

**Interfaces:**
- Consumes: `PTTManager.shared`(现有单例);新增两个 MainActor 方法暴露给生命周期钩子:
  - `func appWillEnterForeground()`  // powerState 为真则 wsClient.start(当前频道)
  - `func appDidEnterBackground()`   // wsClient.stop()(保留成员身份,回落 APNs)

- [ ] **Step 1: PTTManager 暴露前后台钩子**

在 PTTManager 增加:

```swift
@MainActor
func appWillEnterForeground() {
    guard self.powerState else { return }
    self.wsClient.start(channel: Defaults[.pttChannel])
}

@MainActor
func appDidEnterBackground() {
    // 只断 WS,不发 leave: 仍在频道内,语音回落 APNs
    self.wsClient.stop()
}
```

- [ ] **Step 2: SceneDelegate 挂钩子**

在 `sceneWillEnterForeground` 末尾加:

```swift
Task { @MainActor in
    PTTManager.shared.appWillEnterForeground()
}
```

在 `sceneDidEnterBackground` 末尾加:

```swift
Task { @MainActor in
    PTTManager.shared.appDidEnterBackground()
}
```

- [ ] **Step 3: 编译验证**

Run: `xcodebuild -scheme NoLet -project NoLet.xcodeproj -destination 'generic/platform=iOS' build`
Expected: 编译通过。

- [ ] **Step 4: Commit**

```bash
git add NoLet/PushToTalk/PTTManager.swift NoLet/SceneDelegate.swift
git commit --no-gpg-sign -m "feat(ptt): connect/disconnect websocket on foreground/background"
```

---

## Task 9: 端到端集成验证 (手动)

**Files:** 无代码变更。执行手动联调清单,记录结果。

前置: 服务端 `go run .`(Voice 开启),两台已登录不同 member 的真机(PTT 需真机)。

- [ ] **Step 1: 双端在线走 WS**

两端加入同一频道。A 说话录一段。预期: B 在前台经 WS 收到并自动播放;服务端日志无 APNs 分支;B 地图上 A 标记为"说话中"。

- [ ] **Step 2: 一端后台走 APNs**

B 切后台(WS 断开)。A 再说一段。预期: B 经 APNs PTT 推送在锁屏/后台自动播放(incomingPushResult 路径);无重复播放。

- [ ] **Step 3: presence 位置变化上报**

A 移动位置(模拟或真实)。预期: B 地图上 A 的 pin 位置更新(update 事件经 WS)。

- [ ] **Step 4: 回前台重连拉快照**

B 回前台。预期: wsClient 重连,收到 snapshot,onlineUsers 与 A 对齐。

- [ ] **Step 5: 显式离开广播 leave**

A 关闭频道(powerState off / leaveChannel)。预期: B 的 onlineUsers 移除 A(leave 事件);A 强杀不发 leave 时,B 下次重连 snapshot 纠正。

- [ ] **Step 6: WS 发送失败标记**

断网状态下 A 说话。预期: 该 AudioMessage 状态变 failed,弹"发送语音失败"提示。

无自动化断言(硬件/框架依赖),逐项人工确认后勾选并在 PR 描述记录结果。
