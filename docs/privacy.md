# 隐私如何泄露

一条推送从发送到接收经过路线是：<br>
发送端 <font color='red'> →服务端①</font> → 苹果APNS服务器 → 你的设备 → <font color='red'>NoLet APP②</font>。

红色的两处地方可能泄露隐私 <br>
* 发送端未使用HTTPS或使用公共服务器*（作者会看到请求日志）*
* NoLet App 本身不安全，上传到 App Store 的版本经过修改。

#### 解决服务端隐私问题
* 你可以使用开源的后端代码，自行[部署后端服务](/deploy.md)，开启HTTPS。
* 使用自定义秘钥的[加密推送](/encryption) ，加密推送内容

#### 保证 APP 完全由开源代码构建
为确保 App 是安全、未经任何人（包含作者）修改过的，NoLet 是由 Apple Xcode Cloud 构建后上传到 App Store。

*这里不考虑iOS是否泄露隐私*