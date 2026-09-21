# AGConnect Serverless SDK for HarmonyOS

## 简介

AppGallery Connect Serverless针对应用开发领域做了深度支持。提供了主流应用平台的支持，完善的用户认证体系，以及丰富的应用领域微解决方案，可帮助开发者高效构建应用。
面向鸿蒙开发者，提供了端云一体化开发的开发体验。开发者可以在DevEco Studio中基于统一的技术栈，高效、协同地完成端、云代码的编写、调试、编译和部署，极大提高开发者构建鸿蒙应用和元服务的效率。

提供了多种云端服务：
* 认证服务：助力应用快速构建安全可靠的用户认证系统
* 云函数： 提供Serverless化的代码开发与运行平台
* 云数据库：提供端云数据的协同管理
* 云存储：助力应用存储图片、音频、视频等内容，并提供高品质的上传、下载、分享能力
* 

[Learn More](https://developer.huawei.com/consumer/cn/doc/development/AppGallery-connect-Guides/agc-serverless-overview-0000001509965245)

## 下载安装

```
ohpm install @hw-agconnect/cloud
```

OpenHarmony ohpm 环境配置等更多内容，请参考[**如何安装** OpenHarmony ohpm 包]

## 使用说明

```
import cloud from '@hw-agconnect/cloud';
```

##  需要权限

无

## 使用示例

### 认证服务

1. 手机号登录

   ```
   import cloud { Auth, VerifyCodeAction }  from '@hw-agconnect/cloud';
   
   // 申请验证码
   cloud.auth().requestVerifyCode({
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
   import cloud { Auth, VerifyCodeAction }  from '@hw-agconnect/cloud';
   
   // 申请验证码
   cloud.auth().requestVerifyCode({
     action: VerifyCodeAction.RESET_PASSWORD,
     lang: 'zh_CN',
     sendInterval: 60,
     verifyCodeType: {
       email: "your_email@xxx.com",
       kind: "email",
     }
   })
   
   // 登录
   let signInResult = auth.signIn({
     autoCreateUser: true,
     credentialInfo: {
       kind: "email",
       email: "your_email@xxx.com",
       verifyCode: "验证码"
     }
   })
   let user = signInResult.getUser();
   ```
3. 获取当前用户信息
   ```
   import cloud { Auth }  from '@hw-agconnect/cloud';
   cloud.auth().getCurrentUser().then((user) => {
     if (user == null) {
      console.info('no user login in')
     } else {
     console.info('getcurrentUser success: getUid' + user.getUid())
   }
   ```

###  云函数

   ```
  import cloud from '@hw-agconnect/cloud';

  cloud.callFunction({
     name: "test-harmony",
     params: {}
   }).then(functionResult => {
     console.info("query success : " + JSON.stringify(functionResult))
   }).catch(reason => {
     console.info( "query err------------" + reason)
   });
   ```

### 云数据库

1. 更新插入
   ```
   import cloud, { DatabaseConfig, ObjectTypeInfo } from '@hw-agconnect/cloud';
   import { BookInfo } from './BookInfo';
   import schema from './app-schema.json';
   
   let objectTypeInfo: ObjectTypeInfo = schema;
   let config: DatabaseConfig = { objectTypeInfo: objectTypeInfo, zoneName: "QuickStartDemo" };
   let database = cloud.database(config);
   let book: BookInfo = new BookInfo();
   book.setId(2000);
   book.setBookName('book_name_002')
   let record = await database.collection(BookInfo).upsert(book);
   console.info('upsert success :' + record);
   ```

2. 查询
   ```
   // 省略初始化步骤
   let database = cloud.database(config);
   let resuylt = await database.collection(BookInfo).query()
   .equalTo('author', 'zhangsan')
   .greaterThan('price', 100)
   .get();
   console.info('query success :' + JSON.stringify(resuylt));
   ```

3. 删除
   ```
   // 省略初始化步骤
   let database = cloud.database(config);
   let record = await database.collection(BookInfo)
       .delete({
         "id": 2000
       });
   console.info('delete success :' + record);
   ```

### 云存储

1. 上传
   ```
   import cloud, { ProgressEvent, Storage } from '@hw-agconnect/cloud';
   
   public async upload(localPath: string, cloudPath: string) {
    let upRes = await cloud.storage().upload({
      localPath: localPath,
      cloudPath: cloudPath,
      onUploadProgress: (p: ProgressEvent) => {
        console.info(`onUploadProgress:bytes:${p.loaded} total:${p.total}`)
      }
    })
    console.info(`upRes:${JSON.stringify(upRes)}`)
   }
   ```
   
2. 下载

   ```
   import cloud, { ProgressEvent, Storage } from '@hw-agconnect/cloud';
   
   public async upload(localPath: string, cloudPath: string) {
    let downRes = await cloud.storage().download({
      localPath: localPath,
      cloudPath: cloudPath,
      onDownloadProgress: (pe: ProgressEvent) => {
        console.info(`onDownloadProgress:bytes:${pe.loaded} total:${pe.total}`)
      }
    })
    console.info(`downloaded downBytes:${downRes.bytesTransferred} totalBytes:${downRes.totalByteCount}`)
   }
   ```
## 约束与限制

在下述版本验证通过： DevEco Studio: 4.0 Release(4.0.1.601), SDK: API10 (4.0.10.11)

## License

hmcore sdk is licensed under the: "ISC" 