# AGConnect Core SDK for HarmonyOS 

## 简介

AppGalleryConnect Core 是AGC业务的基础核心SDK，提供以下能力：

* 提供AGC 上层业务SDK(Serverless、增长类服务)初始化
* 提供读取agconnect-services.json配置文件的接口
* 提供AAID获取接口
* 提供对接AGC端侧网关的能力，SDK提供接口获取网关的认证凭据

[Learn More](https://developer.huawei.com/consumer/cn/doc/development/AppGallery-connect-Guides/agc-get-started-harmony-ts-0000001534932433)

## 下载安装

```
ohpm install @hw-agconnect/hmcore
```

OpenHarmony ohpm 环境配置等更多内容，请参考[**如何安装** OpenHarmony ohpm 包]

## 使用说明

```
import { initialize } from "@hw-agconnect/hmcore";
```

##  需要权限

无

## 使用示例

### 初始化

1. 在您的项目中导入agc组件。

   ```
   import { initialize } from "@hw-agconnect/hmcore";
   
   // 导入你在AGC网站上下载的agconnect-services.json文件
   import json from '../agconnect-services.json';
   ```

2. 在您的应用初始化阶段使用context初始化SDK，推荐在EntryAbility的onCreate中进行。

   ```
   //初始化SDK
   onCreate(want, launchParam) {
     //请确认agconnect-services.json文件是否存在，文件位置不做约束，由开发者自行导入
      initialize(this.context, json);
   }
   ```

###  获取agconnect-services.json配置文件内容

SDK完成初始化后，可以调用接口获取agconnect-services.json文件的内容（agconnect-services.json中部分内容为加密存储，通过SDK获取到的结果为最终解密后的结果）。

1. 采用通用方法获取
   ```
   import { getString } from "@hw-agconnect/hmcore";

   let client_id = getString('/client/client_id');
   ```
2. 直接通过SDK提供的方法获取
   ```
   import { getRegion } from "@hw-agconnect/hmcore";

   let region = getRegion();
   ```
3. 获取agconnect-services.json中的加密数据
   ```
   import { getClientSecret,getApiKey } from "@hw-agconnect/hmcore";

   let clientSecret = await getClientSecret();
   let apiKey = await getApiKey();
   ```
### 获取AAID

SDK完成初始化后，获取AAID
   ```
   import { getAaid } from "@hw-agconnect/hmcore";
   
   let aaid = await getAaid();
   ```

### 获取AGC网关的认证凭据

   ```
   import { getToken } from "@hw-agconnect/hmcore";
   
   let token = await getToken();
   ```

## 约束与限制

在下述版本验证通过： DevEco Studio: 4.0 Release(4.0.1.601), SDK: API10 (4.0.10.11)

## License

hmcore sdk is licensed under the: "ISC" 