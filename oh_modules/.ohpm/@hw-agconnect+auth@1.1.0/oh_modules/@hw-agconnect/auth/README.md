# AGConnect 认证服务

## 简介

认证服务可以为您的应用快速构建安全可靠的用户认证系统，您只需在应用中访问认证服务的相关能力，而不需要关心云侧的设施和实现。

* 支持手机帐号注册和登录。
* 支持邮箱帐号注册和登录。
* 支持华为账号登录。
* 支持获取用于CloudFoundationKit初始化方法的AuthProvider。

[Learn More](https://developer.huawei.com/consumer/cn/doc/development/AppGallery-connect-Guides/agc-auth-introduction-0000001053732605)

## 下载安装

```
ohpm install @hw-agconnect/auth
```

OpenHarmony ohpm 环境配置等更多内容，请参考[如何安装 OpenHarmony ohpm 包]

## 使用说明

```
import auth from '@hw-agconnect/auth';
```

## 需要权限

```
ohos.permission.INTERNET
```

## 使用示例

### 初始化

1. 在您的项目中导入agc组件。

   ```
   import auth from '@hw-agconnect/auth';
   ```

2. 在您的应用初始化阶段使用context初始化SDK，推荐在MainAbility 的onCreate中进行。

   ```
   //初始化SDK
   onCreate(want, launchParam) {
     //务必保证resources/rawfile中包含agconnect-services.json文件
    let file =  this.context.resourceManager.getRawFileContentSync('agconnect-services.json');
    let json: string = buffer.from(file.buffer).toString();
    auth.init(this.context, json);
   }
   ```

### 主要功能

1. 手机号登录

   ```
   import auth from '@hw-agconnect/auth';
   import { AuthUser, VerifyCodeAction } from '@hw-agconnect/auth';
   
   // 申请验证码
   auth.requestVerifyCode({
     action: VerifyCodeAction.RESET_PASSWORD,
     lang: 'zh_CN',
     sendInterval: 60,
     verifyCodeType: {
       phoneNumber: "188********",
       countryCode: "86",
       kind: "phone",
     }
   })
   
   // 登录
   let signInResult = auth.signIn({
     autoCreateUser: true,
     credentialInfo: {
       kind: "phone",
       phoneNumber: "188********",
       countryCode: "86",
       verifyCode: "验证码"
     }
   })
   let user = signInResult.getUser();
   ```

2. 邮箱登录

   ```
   import auth from '@hw-agconnect/auth';
   import { AuthUser, VerifyCodeAction } from '@hw-agconnect/auth';
   
   // 申请验证码
   auth.requestVerifyCode({
     action: VerifyCodeAction.RESET_PASSWORD,
     lang: 'zh_CN',
     sendInterval: 60,
     verifyCodeType: {
       email: "your_email@xxx.com",
       kind: "email",
     }
   })
   
   // 登录
   let signInResult = await auth.signIn({
     autoCreateUser: true,
     credentialInfo: {
       kind: "email",
       email: "your_email@xxx.com",
       verifyCode: "验证码"
     }
   })
   let user = signInResult.getUser();
   ```
3. 华为账号登录

   ```
   import auth, { AuthUser } from '@hw-agconnect/auth';
   
   let signInResult = await auth.signIn({
     autoCreateUser: true,
     credentialInfo: {
       kind: "hwid"
     }
   })
   let user = signInResult.getUser();
   ```

4. 获取当前用户信息

   ```
   import auth from '@hw-agconnect/auth';
   import { AuthUser, TokenResult } from '@hw-agconnect/auth';
   auth.getCurrentUser().then((user) => {
     if (user == null) {
      console.info('no user login in')
     } else {
     console.info('getcurrentUser success: getUid' + user.getUid())
   }
   ```


5. 获取用于CloudFoundationKit初始化的AuthProvider

   ```
   import auth from '@hw-agconnect/auth';
   
   let provider =  auth.getAuthProvider();
   ```

## 约束与限制

在下述版本验证通过： DevEco Studio NEXT Developer Beta1(5.0.3.403), SDK: API12 Release(5.0.0.25)

## License

auth-ohos sdk is licensed under the: "ISC" 