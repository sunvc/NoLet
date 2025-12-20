_感谢[BARK](https://github.com/Finb/Bark) 的开源项目_

当你需要集成 NoLet 到自己的系统或重新实现后端代码时可能需要推送证书

##### 有效期到: _永久_

##### Key ID：_BNY5GUGV38_

##### TeamID：_FUWV6U942Q_

##### 下载地址：[AuthKey.p8](https://s3.wzs.app/AuthKey_BNY5GUGV38_FUWV6U942Q.p8)

## 也可以直接调用签名接口 data(token) 在 expiry 过期前一直有效

```sh
curl -X POST https://wzs.app
{
  code: 200,
  data: "eyJhbGciOiJFUzI1NiIsImtpZCI6IkJOWTVHVUdWMzgifQ.eyJpYXQiOjE3NjYxMTE1ODMsImlzcyI6IkZVV1Y2VTk0MlEifQ.kODSSHRNbKS4vj2Wxcyuqxcmyw6xxnoR2ANMfoFXBNmIwKeN7vyga5HMsvCeArjwTQMVwi-nJrxUHUndclQ17g",
  expiry: 1766114583,
  timestamp: 1766111594
}
```
