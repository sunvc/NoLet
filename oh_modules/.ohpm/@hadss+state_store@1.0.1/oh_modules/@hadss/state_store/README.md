# 简介

本示例展示了使用StateStore状态管理库实现全局状态管理，覆盖场景：

- UI与状态数据解耦
- 子线程进行状态对象更新
- 状态更新日志埋点

解决开发者在使用ArkUI状态管理时UI组件和数据操作逻辑高度耦合的问题

# 效果预览

![img.png](./screenshots/effect.png)

# 工程目录

```text
├──entry/src/main/ets                       // 代码区
├──constants                                // 常量区
│   └──MiddlewareStatus.ets                 // 中间件状态
├──core                                     // 内核区
│   ├──CombineReducers.ets                  // 连接处理类
│   ├──CreateStore.ets                      // 存储创造类
│   ├──ExecuteMiddleware.ets                // 执行中间件类
│   ├──StateStore.ets                       // 状态存储类
│   └──Stores.ets                           // 存储类
├──log                                      // 日志区
│   ├──ErrorCode.ets                        // 错误代码类
│   └──StoreLogger.ets                      // 存储日志类
├──types                                    // 类型区
│   ├──Actions.ets                          // 自动化类
│   ├──Dispatch.ets                         // 派发类
│   ├──Middleware.ets                       // 中间件类
│   ├──Reducers.ets                         // 处理状态类
│   └──Store.ets                            // 存储类
└──utils                                    // 工具区
    └──JudgeUtils.ets                       // 评测工具                                  
```

# 具体实现
StateStore是一款专为ArkUI深度定制的轻量级状态管理库，通过全家单例维护以HashMap存储的多实例Store，实现业务逻辑与UI的彻底解耦。其核心遵循Redux模式，在执行dispatch时，状态会严谨地流经中间件过滤、Action钩子链及Reducer更新，利用中间件的DROP或Action替换机制确保状态流转的一致性和可追溯行。该方案完美适配@Observed/@ObservedV2实现数据的响应式更新，并底层封装了Emitter与TaskPool/Worker机制，支持将@Sendable标记的任务在非UI线程处理后同步至主线程，有效解决复杂业务下的组件耦合难题，保障前台界面的流畅。

# StateStore简介

StateStore作为ArkUI状态与UI解耦的解决方案，支持全局维护状态，优雅地解决状态共享的问题。

StateStore库提供共享模块StateStore单例，支持根据唯一标识创建store存储对象，管理应用的全局状态，通过事件分发更新状态。依赖系统@Observed和@ObservedV2对数据改变监听的能力，驱动UI刷新。

目的是让开发者在开发过程中实现状态与UI解耦，多个组件可以方便地共享和更新全局状态，将状态管理逻辑从组件逻辑中分离出来，简化维护。

# 特性

+ 状态与UI解耦，支持数据全局化操作
+ 简化子线程并行化操作
+ 支持对数据逻辑执行预处理和后处理

# 约束与限制

SDK: Ohos_sdk_public 5.0.0.71 (API 12 Release)及以上

# 下载安装

## 使用ohpm安装依赖

```shell
ohpm install @hadss/state_store
```

> 或者按需在模块中配置运行时依赖，修改oh-package.json5
> 
```json5
{
  "dependencies": {
    "@hadss/state_store": "^1.0.0-rc.3"
  }
}
```

## StateStore框架使用说明

[查看说明](https://gitcode.com/openharmony-sig/state_store/blob/master/README.md)

# StateStore接口和属性列表

[查看详情](https://gitcode.com/openharmony-sig/state_store/blob/master/docs/Reference.md)

# SampleCode

本项目包含[Sample示例代码](https://gitcode.com/HarmonyOS_Samples/StateStore)，通过TODO待办列表展示StateStore在全局状态管理场景中的使用


# FAQ

[查看详情](https://gitcode.com/openharmony-sig/state_store/blob/master/docs/FAQ.md)

# 原理介绍

本解决方案的思路参考[redux](https://redux.js.org/api/store)和[vuex](https://vuex.vuejs.org/guide/actions.html)的全局状态管理的实现。具体原理可以学习redux和vuex，对理解本库的实现和使用有帮助。

# 贡献代码

使用过程中发现任何问题都可以提 [Issue](https://gitcode.com/openharmony-sig/state_store/issues) ，当然，也非常欢迎发 [PullRequest](https://gitcode.com/openharmony-sig/state_store/pulls) 共建。

# 开源协议

本项目基于 [Apache License 2.0](https://gitcode.com/openharmony-sig/state_store/blob/master/LICENSE) ，请自由地享受和参与开源。