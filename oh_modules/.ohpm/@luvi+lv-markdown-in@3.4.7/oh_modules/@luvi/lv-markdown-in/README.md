![Segment](https://agc-storage-drcn.platform.dbankcloud.cn/v0/segment-xm2dk/%E5%AE%A3%E4%BC%A0%E5%9B%BE%2F%E6%A8%AA%E5%B9%85%E5%AE%A3%E4%BC%A0.png?token=6a808f20-a77a-425f-b989-6fa5a08dc6c4)

![宣传图](https://agc-storage-drcn.platform.dbankcloud.cn/v0/shangshu-data-rfayj/markdown_banner.png?token=207bf00f-9060-4ec6-9c67-5de906c4da42)

## 简介

鸿蒙原生 **Markdown** 解析与渲染三方库，一款专为 **OpenHarmony** 与 **HarmonyOS** 系统设计的工业级原生 Markdown 渲染解决方案。让
Markdown 内容在界面中拥有更平滑的性能表现与更统一的视觉体验。

该库以高性能与原生体验为核心，支持**插件拓展**、**数学公式本地渲染**、**Mermaid 图表渲染**、**流式数据渲染**、**大文本懒渲染
**、**Worker 子线程加载**
，并提供 **70+
可定制样式 API**，助力开发者灵活定义
Markdown
内容的视觉风格与交互体验。从基础文本排版到复杂组件布局，都能精确适配系统特性。

充分结合鸿蒙资源机制，支持 **三种内容加载模式**：

- 纯文本加载：适用于动态内容；
- 资源文件加载：便于内置模板与预设内容展示；
- 沙箱文件加载：保障用户内容安全与私有化存储。

适配 **$rawfile 原生资源图片加载能力**
，并支持 **html常用标签解析** 与 **图片加载代理**，兼顾 Markdown 与富文本场景的灵活性。

注：因隐私政策调整（文末附[隐私政策](#隐私政策)），从 v3.1.0 版本开始，移除原有代码块和文本的复制文本到剪贴板的能力，请通过
[MarkdownController.setCodeCopyListener()](#setcodecopylistener)
和[MarkdownController.setTextSelectionCopyListener()](#setTextSelectionCopyListener) 接口注册代码块复制监听，并自行调用
pasteboard
系统接口实现代码块的复制处理逻辑。

## lv-markdown-in 目前支持

| 基本语法                                                                | 拓展语法                                                                                 | 
|---------------------------------------------------------------------|--------------------------------------------------------------------------------------|
| [标题](https://markdown.com.cn/basic-syntax/headings.html)            | 数学公式                                                                                 |
| [段落](https://markdown.com.cn/basic-syntax/paragraphs.html)          | [表格](https://markdown.com.cn/extended-syntax/tables.html)                            |
| [换行](https://markdown.com.cn/basic-syntax/line-breaks.html)         | [代码块](https://markdown.com.cn/extended-syntax/fenced-code-blocks.html)               |
| [强调（粗体、斜体、粗斜体）](https://markdown.com.cn/basic-syntax/emphasis.html) | [脚注](https://markdown.com.cn/extended-syntax/footnotes.html)                         |
| [引用块](https://markdown.com.cn/basic-syntax/blockquotes.html)        | [任务列表](https://markdown.com.cn/extended-syntax/task-lists.html)                      | 
| [列表](https://markdown.com.cn/basic-syntax/lists.html)               | [删除线](https://markdown.com.cn/extended-syntax/strikethrough.html)                    | 
| [代码](https://markdown.com.cn/basic-syntax/code.html)                | [html常用标签解析](https://ohpm.openharmony.cn/#/cn/detail/@luvi%2Fhtml2md)（含 `font` 快速样式） |
| [分割线](https://markdown.com.cn/basic-syntax/horizontal-rules.html)   | Mermaid 图表渲染                                                                         |
| [链接](https://markdown.com.cn/basic-syntax/links.html)               |                                                                                      | 
| [图片](https://markdown.com.cn/basic-syntax/images.html)              |                                                                                      |

## 立即使用

1.运行命令

``` shell
ohpm install @luvi/lv-markdown-in
```

2.在项目中引入插件

``` javascript
import { Markdown } from @luvi/lv-markdown-in
```

3.在代码中使用

``` javascript
Markdown({ text: "想让文字像在原生世界里呼吸，就得从**渲染**开始" })
```

## 升级指南

2.0 及之前版本中的 LvMarkdownIn() 组件已弃用，可以**使用 3.0 及以上导出的 Markdown() 组件，体验最新版本的改动**。

**组件及字段变更：**

| 旧版本              | 变更          | 说明                                                          |
|------------------|-------------|-------------------------------------------------------------|
| ~~LvMarkdownIn~~ | Markdown    | **使用 Markdown() 组件，体验最新版本的改动**。                             |
|                  | controller  | 新增 MarkdownController 控制器。<br>样式、图片，超链接点击监听拦截、图片代理均由此控制器完成。 |
|                  | plugins     | 自定义插件列表，将匹配结果渲染为对应自定义组件。                                    |
| text             | text        | markdown 文本内容，保持不变。                                         |
| ~~loadMode~~     | mode        | 加载模式，字段名称调整。                                                |
| context          | context     | 上下文，保持不变。                                                   |
| rawfilePath      | rawfilePath | 资源文件路径，保持不变。                                                |
| sandboxPath      | sandboxPath | 沙箱文件路径，保持不变。                                                |
| ~~loadCallBack~~ | callback    | 字段名称调整。                                                     |

## HTML 快速样式

增强版 `Markdown` 组件支持行内 `<font>` 标签的快速样式设置，当前支持 `color`、`size`、`face` 三个属性，适合对少量文本做快速定制。

``` html
<span style="color: #ff0000">span style color example</span>
<font color="red" size="24px">内容</font>
<font color="#0A59F7" size="3" face="SmileySans-Oblique-3">你好</font>
```

说明：当前仅支持 `font` 标签包裹纯文本内容，不支持在 `font` 内继续嵌套 markdown 或其他 HTML 标签。

## 多种内容加载模式（纯文本、资源文件、沙箱文件）

### 1. 纯文本模式（text）

``` javascript
Markdown({
    text: "想让文字像在原生世界里呼吸，就得从**渲染**开始",
    mode: "text",               // 默认 text 可省略
    callback: {                 // callback 可省略
      complete: () => {
        console.log("Markdown component load success.")
      },
      fail: (code: number, message: string) => {
        console.error("Markdown component load error. code: " + code + ", message: " + message)
      }
    }
})
```

### 2. 资源文件模式（rawfile）

使用资源文件模式，`需要将 mode 字段设置为 rawfile`，rawfilePath 需要填写模块中 rawfile
目录的文件路径，同时需要传递应用上下文context，callback 为可选参数，用于资源加载时的回调检查。

``` javascript
Markdown({
    mode: "rawfile",
    context: getContext(),      // 资源文件模式必填参数
    rawfilePath: "t/text.md",   // 资源文件地址
    callback: {                 // callback 可省略
      complete: () => {
        console.log("Markdown component load success.")
      },
      fail: (code: number, message: string) => {
        console.error("Markdown component load error. code: " + code + ", message: " + message)
      }
    }
})
```

### 3. 沙箱文件模式（sandbox）

使用沙箱文件模式，`需要将 mode 字段设置为 sandbox`，callback 为可选参数，用于资源加载时的回调检查。

``` javascript
Markdown({
    mode: "sandbox",
    sandboxPath: getContext().getApplicationContext().filesDir + "/t2/text.md",
    callback: {                 // callback 可省略
      complete: () => {
        console.log("Markdown component load success.")
      },
      fail: (code: number, message: string) => {
        console.error("Markdown component load error. code: " + code + ", message: " + message)
      }
    }
})
```

## 插件拓展 `new 3.4.0+`

Markdown 组件支持通过实例级 plugins 配置扩展自定义语法，并将匹配结果渲染为对应自定义组件；
_[MarkdownPlugin](#MarkdownPlugin)、[PluginNode](#PluginNode)
详细接口设计请跳转对应章节查看_
。详细实现示例可参阅文章：[插件扩展操作指导](https://developer.huawei.com/consumer/cn/blog/topic/03212709193747056)。

- 支持块级插件与内联插件
- 语法通过正则表达式定义
- 支持命名捕获组，匹配结果可通过 node.params 获取
- 文本复制时，内联插件默认复制原始语法串

``` javascript
import { Markdown, MarkdownController, MarkdownPlugin, PluginNode } from '@luvi/lv-markdown-in'

const plugins: MarkdownPlugin[] = [
  // [ref_1]、[ref_2]、[ref_n]
  {
    key: 'ref',
    display: 'inline',
    pattern: String.raw`\[ref_(?<id>\d+)\]`,
    matchMode: 'inline-prefix',
    inlineLayout: (_node: PluginNode) => {
      return { width: 20, height: 10 }
    },
    render: wrapBuilder<[PluginNode]>(RefPluginBuilder)
  },
  // <trend_chart>
  {
    key: 'trend_chart',
    display: 'block',
    pattern: String.raw`^<trend_chart>$`,
    matchMode: 'full-line',
    render: wrapBuilder<[PluginNode]>(TrendChartPluginBuilder)
  }
]

const PLUGIN_TEXT = `# Plugin Demo\n\n这是一个内联引用插件 [ref_1]，它会渲染成一个胶囊标签。\n\n继续测试多个引用 [ref_2] 与普通文本混排，复制时仍然保留原始语法。\n\n<trend_chart>\n\n图表块下方依然是普通段落。`

Markdown({
  controller: this.controller,
  text: PLUGIN_TEXT,
  plugins: plugins
})

@Builder
function RefPluginBuilder(node: PluginNode) {
  ...
  Text(node.params?.id || '--')
    .width(20)
    .height(10)
  ...
}

@Builder
function TrendChartPluginBuilder(_node: PluginNode) {
  ...
  Text('趋势图组件')
  ...
}
```

## 超链接、图片、公式点击，自定义控制跳转行为

需要注意的是，使用拦截行为后，`return true` 才可拦截正常拦截库中默认打开行为，`return false` 则不拦截，但会进入该逻辑。

数学公式点击监听仅在公式已经成功渲染并拿到 `pixelMap` 时才会触发；若公式仍处于文本兜底状态，则不会触发该回调。当前库内未提供公式默认点击行为，
`return false` 时不会继续执行其他动作。

``` javascript
// 导入 MarkdownController
import { MarkdownController } from '@luvi/lv-markdown-in'
import { image } from '@kit.ImageKit'

// 注册超链接点击回调，return true 则表示拦截，自行处理超链接跳转逻辑
this.markdownController.setHyperlinkClickListener((title, src, anchorInfo) => {
    console.log("拦截跳转 title: " + title) // 标题
    console.log("拦截跳转 src: " + src) // 网页地址
    console.log("锚点信息 anchorInfo: " + JSON.stringify(anchorInfo)) // 锚点位置信息
    promptAction.showToast({ message: title + "\n" + src })
    return true
})

// 注册图像点击回调，return true 则表示拦截，自行处理图像展示逻辑
this.markdownController.setImageClickListener((src: string) => {
    console.log("拦截跳转 src: " + src) // 图片地址
    promptAction.showToast({ message: src })
    return true
})

// 注册公式点击回调，需等待公式成功渲染出 pixelMap 后才会触发
this.markdownController.setLatexClickListener((text: string, pixelMap: image.PixelMap) => {
    console.log("latex text: " + text) // 公式原文
    console.log("latex pixelMap: " + JSON.stringify(pixelMap.getImageInfoSync()))
    return true
})
```

## 动态样式改变

需在 Markdown 渲染完成后动态改变样式，可以**绑定
MarkdownController
至对应 Markdown 组件**后直接**调用
MarkdownController 的多样化接口设置样式**。

## $rawfile原生资源图片加载

$rawfile 加载本地图片资源，语法示例：

```markdown
![]($rawfile("images/raw-pic.png"))
```

## 锚点跳转 `new 3.2.6+`

1. 通过标题的自动锚点实现（标题包含特殊字符时可能失效）。

``` markdown
[跳转到二级标题](#二级标题)  <!-- 需与标题完全一致 -->
## 二级标题
[跳转到三级标题](#三级标题)  <!-- 需与标题完全一致 -->
### 三级标题
```

2. 拦截锚点超链接，获取锚点在屏幕上的位置信息，页面滚动容器绑定Scroller，滚动至页面指定位置。

``` javascript
this.markdownController.setHyperlinkClickListener((title, src, anchorInfo) => {
  console.log("锚点信息 anchorInfo: " + JSON.stringify(anchorInfo)) // 锚点位置信息
  if (anchorInfo) {
    // 页面滚动容器绑定Scroller，滚动至页面指定位置
    this.scroll.scrollTo({
      yOffset: px2vp(anchorInfo?.screenOffset.y),
      xOffset: 0,
      animation: { duration: 200 }
    })
    return true
  }
  return false
})
```

## 自定义图片尺寸 `new 3.2.6+`

通过直接在图片链接后添加尺寸参数(如 =600x400)，该值优先级高于通用图片尺寸设置。

- 格式：`![Alt text](image_url =widthxheight)`。
- 示例：`[我的图片](https://example.com/image.png =600x400)`
- 等比例缩放：
    - 只指定宽度：`![我的图片](https://example.com/image.png =600x)`。
    - 只指定高度：`![我的图片](https://example.com/inage.png =x400)`。
- 注意：`=`号前通常需要一个空格。

## 深色模式

在代码中引用自定义的颜色资源值，使用 `$r` 加载自定义颜色资源，系统将自动在应用深浅色变化时，加载对应限定词目录下的资源文件，从而改变
Markdown
元素的颜色完成深浅色适配。详细可参阅文章：[ArkUI深色模式适配指南](https://developer.huawei.com/consumer/cn/blog/topic/03195774342899131)

```arkts
import { Markdown, MarkdownController } from '@luvi/lv-markdown-in';

@Entry
@Component
struct Dark {
    controller: MarkdownController = new MarkdownController()
    @State content: string = `
      ## 鸿蒙原生应用开发笔记
      *鸿蒙原生*，意味着**纯净**与**性能**的平衡。
      > 想让文字像在原生世界里呼吸，就得从渲染开始。
    `

    aboutToAppear(): void {
        // 深色模式适配
        this.controller
            .setTitleColor($r("app.color.title"))
            .setTextColor($r("app.color.primary_text"))
            .setQuoteBackgroundColor($r("app.color.quote_bgc"))
    }

    build() {
        Scroll() {
            Markdown({
                controller: this.controller,
                text: this.content
            })
        }
        .padding({
            left: 15,
            right: 15,
            top: 60,
        })
    }
}
```

## Markdown

承载 Markdown 内容渲染的组件。项目采用 v1 + v2 装饰器混合开发，可同时在 v1 或 v2 项目中使用。

**装饰器类型：** @Component

**参数**

| 名称          | 类型                                            | 必填 | 装饰器类型 | 说明                                                                                                                                  |
|-------------|-----------------------------------------------|----|-------|-------------------------------------------------------------------------------------------------------------------------------------|
| controller  | MarkdownController \|  undefined              | 否  | @Prop | 通过 MarkdownController 可以控制 Markdown 组件各种行为，如：自定义样式、设置图片点击拦截、设置超链接点击拦截等。                                                             |
| text        | string \| undefined                           | 否  | @Prop | markdown 文本内容。                                                                                                                      |
| plugins     | MarkdownPlugin[] \|  undefined                | 否  | /     | 配置扩展自定义语法，并将匹配结果渲染为对应自定义组件。                                                                                                         |
| mode        | "text" \| "rawfile" \| "sandbox" \| undefined | 否  | @Prop | Markdown 组件加载模式，支持纯文本加载、沙箱文件加载、资源文件加载，不填默认为 "text"。                                                                                 |
| context     | Context \| undefined                          | 否  | /     | mode 字段设置为 rawfile 时， context 为必填项。                                                                                                 |
| rawfilePath | string \| undefined                           | 否  | @Prop | mode 字段设置为 rawfile 时， rawfilePath 为必填项，需传入 resources/rawfile 目录下对应的 rawfile 文件路径。                                                   |
| sandboxPath | string \| undefined                           | 否  | @Prop | mode 字段设置为 sandbox 时， sandboxPath 为必填项，需传入沙箱 text/md 文件的完整沙箱路径。<br>例：getContext().getApplicationContext().filesDir + "/t2/text.md"。 |
| callback    | MdCallback \| undefined                       | 否  | /     | Markdown 组件加载状态结果告知。用于组件加载完成时，组件加载失败时回调，并返回错误码 code，错误信息 message，可用于问题分析。                                                           |

## MarkdownPlugin

`Markdown` 支持通过实例级 `plugins` 注册自定义正则插件，用于扩展块级语法和内联语法。

``` typescript
interface MarkdownPlugin {
  key: string
  display: 'inline' | 'block'
  pattern: string
  flags?: string
  matchMode: 'inline-prefix' | 'full-line'
  selectable?: boolean
  inlineLayout?: (node: PluginNode) => InlinePluginLayout
  renderInline?: (node: PluginNode) => void
  renderBlock?: (node: PluginNode) => void
}
```

| 字段           | 类型                                                       | 必填 | 说明                                                                                  | 
|--------------|----------------------------------------------------------|---:|-------------------------------------------------------------------------------------|
| key          | string                                                   |  是 | 插件唯一标识，同一个 Markdown 实例内建议唯一。解析后的 PluginNode.pluginKey 会使用该值。                        | 
| display      | 'inline' \| 'block'                                      |  是 | 插件类型。inline 表示内联插件，参与段落文本流；block 表示块级插件，独占一行渲染。                                     | 
| pattern      | string                                                   |  是 | 正则表达式字符串。建议使用 String.raw，避免 \d、\[ 等转义在字符串阶段被吞掉。例如： String.raw\`\[ref_(?<id>\d+)\]\` | 
| flags        | string                                                   |  否 | 正则 flags，例如 'i'、'm'。通常不需要传 'g'。                                                     | 
| matchMode    | 'inline-prefix' \| 'full-line'                           |  是 | 匹配模式。内联插件使用 inline-prefix；块级插件通常使用 full-line。                                       | 
| selectable   | boolean                                                  |  否 | 是否参与跨 Text 选区复制。仅内联插件有效，默认参与复制；设置为 false 后不会进入复制结果。                                 | 
| inlineLayout | (node: PluginNode) => { width: number; height: number }` |  否 | 声明内联插件占位尺寸。只有配置了 inline，内联插件才会渲染自定义组件。                                              | 
| render       | (node: PluginNode) => void`                              |  否 | 插件的渲染函数。通常传入 @Builder 函数。                                                           | 

说明：

- 内联插件不能直接作为普通组件塞进 ArkUI Text 内部。
- 当前实现会先在 Text 内放一个透明 ImageSpan 占位，再在外层 overlay 渲染真实组件。
- inlineLayout 的宽高应尽量和 renderInline 实际组件尺寸一致。
- 如果内联插件没有配置 inlineLayout，即使配置了 renderInline，也会回退显示原始文本 raw。

## PluginNode

``` typescript
interface PluginNode {
  type: 'plugin'
  pluginKey: string
  display: 'inline' | 'block'
  raw: string
  params?: ESObject
  groups?: string[]
  copyText?: string
  selectable?: boolean
}
```

| 字段           | 类型                    | 必填 | 说明                                            | 来源                          |
|--------------|-----------------------|---:|-----------------------------------------------|-----------------------------|
| `type`       | `"plugin"`            |  是 | 节点类型标识，固定值。                                   | 解析层固定写入                     |
| `pluginKey`  | `string`              |  是 | 对应 `MarkdownPlugin.key`。                      | `MarkdownPlugin.key`        |
| `display`    | `"inline" \| "block"` |  是 | 插件类型。                                         | `MarkdownPlugin.display`    |
| `raw`        | `string`              |  是 | 正则匹配到的原始文本，例如 [ref_1]。                        | 正则命中结果                      |
| `params`     | `ESObject`            |  否 | 命名捕获组结果，例如 (?<id>\d+) 可通过 node.params?.id 读取。 | 正则命名捕获组                     |
| `groups`     | `string[]`            |  否 | 普通捕获组结果，不包含完整匹配。                              | 正则捕获组                       |
| `copyText`   | `string`              |  否 | 复制文本，默认等于 raw。                                | 解析层或后续扩展                    |
| `selectable` | `boolean`             |  否 | 表示该插件节点是否参与文本选择/复制。                           | `MarkdownPlugin.selectable` |

## InlinePluginLayout

| 字段     | 类型     | 必填 | 说明                                   |
|--------|--------|---:|--------------------------------------|
| width  | number |  是 | 内联插件在文本流中的占位宽度，数字单位按 ArkUI 默认 vp 处理。 |
| height | number |  是 | 内联插件在文本流中的占位高度，数字单位按 ArkUI 默认 vp 处理。 |

## MarkdownController

Markdown 组件的控制器。可以将此对象绑定至 Markdown 组件，然后通过它控制 Markdown 组件的自定义样式及线程加载控制。同一个控制器可以控制多个
Markdown 组件，**多个 API 支持链式调用语法**。

- v1 版本开发中不支持使用 @State 装饰器进行修饰，无需使用装饰器修饰。
- v2 版本开发中可支持 v2 装饰器使用。
- 当然，您也可以完全不选择使用装饰器，这并不影响组件的正常渲染。

### 导入对象

``` javascript
// 导入 MarkdownController
import { MarkdownController } from '@luvi/lv-markdown-in'
// 获取对象
markdownController: MarkdownController = new MarkdownController()
```

### setThreadRenderEnable `new 3.2.3+`

setThreadRenderEnable(enable: boolean)

设置是否开启线程加载模式，默认开启。注：该接口请在组件渲染前完成配置，否则不生效。

**参数**

| 参数名    | 类型      | 必填 | 说明                    |
|--------|---------|----|-----------------------|
| enable | boolean | 是  | 设置是否开启线程加载模式，默认：true。 |

**使用示例**

``` javascript
this.controller.setThreadRenderEnable(true)
```

### setSetextHeadingEnable `new 3.4.2+`

setSetextHeadingEnable(enable: boolean)

设置是否开启 Setext 标题解析，默认关闭。开启后，文本下方的 `=====` 和 `-----` 会解析为一级或二级标题。

默认关闭可避免 AI 生成报告、资讯摘要等文本中常见的连续横线分隔写法被误识别为标题：

``` markdown
这是一段完整说明文字。
---------
# 下一节标题
```

标准 CommonMark 会把上面第一行解析成二级标题。默认关闭 Setext 标题解析后，会解析为普通段落、分割线、一级标题。如需兼容标准
Setext 标题语法，可在 Markdown 组件渲染前开启。

注意：默认情况下，`一级标题\n=====` 和 `二级标题\n-----` 两种 Setext 标题语法不会生效。如需标题，请使用 `#` 到 `######` 的
ATX 标题语法，或显式开启 Setext 标题解析。

**参数**

| 参数名    | 类型      | 必填 | 说明                         |
|--------|---------|----|----------------------------|
| enable | boolean | 是  | 是否开启 Setext 标题解析，默认：false。 |

**使用示例**

``` javascript
this.controller.setSetextHeadingEnable(true)
```

### setLazyRender `new 3.4.2+`

setLazyRender(enable: boolean)

设置是否开启可见区域懒渲染。默认关闭。开启后屏幕外块先以轻量占位渲染，进入可见区域附近后再渲染真实内容。

注意：懒渲染为长文性能优化能力，依赖外层滚动容器的可见区域变化触发。开启文本选择时组件会自动回退为普通渲染，以避免屏幕外文本未注册影响选择/复制。

**参数**

| 参数名    | 类型      | 必填 | 说明                |
|--------|---------|----|-------------------|
| enable | boolean | 是  | 是否开启懒渲染，默认：false。 |

**使用示例**

``` javascript
this.controller.setLazyRender(true)
```

### setLazyPreloadBlockCount `new 3.4.2+`

setLazyPreloadBlockCount(count: number)

设置懒渲染预渲染块数量，默认 3。实际渲染会按内部懒渲染分组折算。

**参数**

| 参数名   | 类型     | 必填 | 说明           |
|-------|--------|----|--------------|
| count | number | 是  | 预渲染块数量，默认：3。 |

**使用示例**

``` javascript
this.controller
  .setLazyRender(true)
  .setLazyPreloadBlockCount(3)
```

### setTitleColor `new 3.2.2+`

setTitleColor(color:
ResourceColor | [ResourceColor, ResourceColor, ResourceColor, ResourceColor, ResourceColor, ResourceColor])

设置标题字体颜色，支持给指定级别的标题设置字体颜色。设置数组格式则为指定级别的标题设置字体颜色，设置唯一字体颜色，则1-6级标题全部生效。

**参数**

| 参数名   | 类型                                                                                                          | 必填 | 说明                                            |
|-------|-------------------------------------------------------------------------------------------------------------|----|-----------------------------------------------|
| color | ResourceColor \| [ResourceColor, ResourceColor, ResourceColor, ResourceColor, ResourceColor, ResourceColor] | 是  | 设置标题字体颜色，数组中0-5项分别为1-6级标题字体颜色，默认："#ff1d2c39"。 |

**使用示例**

``` javascript
this.controller.setTitleColor("#000")
或
this.controller.setTitleColor(["#000", "#000", "#000", "#000", "#000", "#000"])
```

### setTitleSize

setTitleSize(
titleSize: [ResourceStr | number, ResourceStr | number, ResourceStr | number, ResourceStr | number, ResourceStr | number, ResourceStr | number])

设置标题字号（1-6级）。

**参数**

| 参数名       | 类型                                                                                                                                          | 必填 | 说明                                                           |
|-----------|---------------------------------------------------------------------------------------------------------------------------------------------|----|--------------------------------------------------------------|
| titleSize | [ResourceStr  \| number, ResourceStr \| number, ResourceStr \| number, ResourceStr \| number, ResourceStr \| number, ResourceStr \| number] | 是  | 设置标题1-6级字号。数组中0-5项分别为1-6级标题字号，默认： [30, 28, 24, 20, 18, 16] 。 |

**使用示例**

``` javascript
this.controller.setTitleSize([30, 28, 24, 20, 18, 16])
```

### setTitleLineHeight

设置标题行高（1-6级）。

setTitleLineHeight(
lineHeights: [ResourceStr | number, ResourceStr | number, ResourceStr | number, ResourceStr | number, ResourceStr | number, ResourceStr | number])

**参数**

| 参数名         | 类型                                                                                                                                          | 必填 | 说明                                                           |
|-------------|---------------------------------------------------------------------------------------------------------------------------------------------|----|--------------------------------------------------------------|
| lineHeights | [ResourceStr  \| number, ResourceStr \| number, ResourceStr \| number, ResourceStr \| number, ResourceStr \| number, ResourceStr \| number] | 是  | 设置标题1-6级行高。数组中0-5项分别为1-6级标题行高，默认： [36, 34, 30, 26, 24, 22] 。 |

**使用示例**

``` javascript
this.controller.setTitleLineHeight([36, 34, 30, 26, 24, 22])
```

### setTitleFontWeight `new 3.2.2+`

setTitleFontWeight(fontWeight: FontWeight | [FontWeight, FontWeight, FontWeight, FontWeight, FontWeight, FontWeight])

设置标题字体粗细，支持给指定级别的标题设置字体粗细。设置数组格式则为指定级别的标题设置字体粗细，设置唯一字体粗细，则1-6级标题全部生效。

**参数**

| 参数名   | 类型                                                                                     | 必填 | 说明                                                |
|-------|----------------------------------------------------------------------------------------|----|---------------------------------------------------|
| color | FontWeight \| [FontWeight, FontWeight, FontWeight, FontWeight, FontWeight, FontWeight] | 是  | 设置标题字体粗细，数组中0-5项分别为1-6级标题字体粗细，默认：FontWeight.Bold。 |

**使用示例**

``` javascript
this.controller.setTitleColor(FontWeight.Bold)
或
this.controller.setTitleColor([FontWeight.Bold, FontWeight.Normal, FontWeight.Medium, FontWeight.Normal, FontWeight.Lighter, FontWeight.Normal])
```

### setTitleFontStyle `new 3.2.2+`

setTitleFontStyle(fontStyle: FontStyle | [FontStyle, FontStyle, FontStyle, FontStyle, FontStyle, FontStyle])

设置标题字体样式（斜体），支持给指定级别的标题设置字体样式。设置数组格式则为指定级别的标题设置字体样式，设置唯一字体样式，则1-6级标题全部生效。

**参数**

| 参数名   | 类型                                                                              | 必填 | 说明                                                 |
|-------|---------------------------------------------------------------------------------|----|----------------------------------------------------|
| color | FontStyle \| [FontStyle, FontStyle, FontStyle, FontStyle, FontStyle, FontStyle] | 是  | 设置标题字体样式，数组中0-5项分别为1-6级标题字体样式，默认：FontStyle.Normal。 |

**使用示例**

``` javascript
this.controller.setTitleFontStyle(FontStyle.Italic)
或
this.controller.setTitleFontStyle([FontStyle.Italic, FontStyle.Italic, FontStyle.Italic, FontStyle.Italic, FontStyle.Italic, FontStyle.Italic])
```

### setTitleFontFamily `new 3.2.4+`

setTitleFontFamily(fontFamily:
ResourceStr | [ResourceStr, ResourceStr, ResourceStr, ResourceStr, ResourceStr, ResourceStr])

设置标题自定义字体（字体族），支持给指定级别的标题设置自定义字体。设置数组格式则为指定级别的标题设置自定义字体，设置唯一自定义字体，则1-6级标题全部生效。

**参数**

| 参数名        | 类型                                                                                             | 必填 | 说明                                    |
|------------|------------------------------------------------------------------------------------------------|----|---------------------------------------|
| fontFamily | ResourceStr  \| [ResourceStr, ResourceStr, ResourceStr, ResourceStr, ResourceStr, ResourceStr] | 是  | 设置标题自定义字体，数组中0-5项分别为1-6级标题自定义字体，默认：无。 |

**使用示例**

``` javascript
let fontStyle = this.getUIContext().getFont()
// 注册得意黑字体, familySrc支持RawFile，确保将自定义字体文件放在entry/src/main/resources/rawfile目录下
fontStyle.registerFont({
  familyName: 'SmileySans-Oblique-3',
  familySrc: $rawfile('font/SmileySans-Oblique-3.otf') // resources/rawfile目录下
})
    
this.controller.setTitleFontFamily('SmileySans-Oblique-3')
或
this.controller.setTitleFontFamily(['SmileySans-Oblique-3', '', 'SmileySans-Oblique-3', '', '', ''])
```

### setTextColor

setTextColor(textColor: ResourceColor)

设置普通文本字体颜色。

**参数**

| 参数名       | 类型            | 必填 | 说明                         |
|-----------|---------------|----|----------------------------|
| textColor | ResourceColor | 是  | 设置普通文本的颜色，默认："#e61f1f39" 。 |

**使用示例**

``` javascript
this.controller.setTextColor("#e61f1f39")
```

### setTextLineHeight

setTextLineHeight(textLineHeight: ResourceStr | number)

设置普通文本字体行高。

**参数**

| 参数名            | 类型                    | 必填 | 说明                  |
|----------------|-----------------------|----|---------------------|
| textLineHeight | ResourceStr \| number | 是  | 设置普通文本的行高，默认：24vp 。 |

**使用示例**

``` javascript
this.controller.setTextLineHeight(24)
```

### setTextSize

setTextSize(textSize: ResourceStr | number)

设置普通文本字号。

**参数**

| 参数名      | 类型                    | 必填 | 说明                  |
|----------|-----------------------|----|---------------------|
| textSize | ResourceStr \| number | 是  | 设置普通文本的字号，默认：16fp 。 |

**使用示例**

``` javascript
this.controller.setTextSize(16)
```

### setTextFontFamily `new 3.2.4+`

setTextFontFamily(fontFamily: ResourceStr)

设置普通文本自定义字体（字体族）。

**参数**

| 参数名        | 类型          | 必填 | 说明                |
|------------|-------------|----|-------------------|
| fontFamily | ResourceStr | 是  | 设置普通文本自定义字体，默认：无。 |

**使用示例**

``` javascript
let fontStyle = this.getUIContext().getFont()
// 注册得意黑字体, familySrc支持RawFile，确保将自定义字体文件放在entry/src/main/resources/rawfile目录下
fontStyle.registerFont({
  familyName: 'SmileySans-Oblique-3',
  familySrc: $rawfile('font/SmileySans-Oblique-3.otf') // resources/rawfile目录下
})
    
this.controller.setTextFontFamily('SmileySans-Oblique-3')
```

### setLatexMathTextSize

setLatexMathTextSize(size: number)

设置数学公式字号。

**参数**

| 参数名  | 类型     | 必填 | 说明                 |
|------|--------|----|--------------------|
| size | number | 是  | 设置数学公式字号，默认：24fp 。 |

**使用示例**

``` javascript
this.controller.setLatexMathTextSize(24)
```

### setLatexMathTextColor

setLatexMathTextColor(color: number)

设置数学公式字体颜色（十六进制）。

**参数**

| 参数名   | 类型     | 必填 | 说明                                |
|-------|--------|----|-----------------------------------|
| color | number | 是  | 设置数学公式-字体颜色（十六进制），默认：0xFF000000 。 |

**使用示例**

``` javascript
this.controller.setLatexMathTextColor(0xFF000000)
```

### setLatexClickListener

setLatexClickListener(event: (text: string, pixelMap: image.PixelMap) => boolean)

设置数学公式点击监听回调。为保持与图片、超链接监听语义一致，**return false 不拦截，return true 拦截**。

仅当公式已经成功渲染并生成 `pixelMap` 时才会触发该回调；如果公式仍处于文本兜底状态或渲染失败，则不会触发。当前库内未提供公式默认点击行为，
`return false` 时不会继续执行其他动作。

**参数**

| 参数名   | 类型                                                  | 必填 | 说明                                                       |
|-------|-----------------------------------------------------|----|----------------------------------------------------------|
| event | (text: string, pixelMap: image.PixelMap) => boolean | 是  | 设置数学公式点击监听回调，默认：(_text, _pixelMap) => { return false } 。 |

**使用示例**

``` javascript
import { image } from '@kit.ImageKit'

this.controller.setLatexClickListener((text: string, pixelMap: image.PixelMap) => {
  console.log("latex text: " + text)
  console.log("latex width: " + pixelMap.getImageInfoSync().size.width)
  return true
})
```

### setInlineCodeColor

setInlineCodeColor(inlineCodeColor: ResourceColor)

设置行内代码颜色。

**参数**

| 参数名             | 类型            | 必填 | 说明                       |
|-----------------|---------------|----|--------------------------|
| inlineCodeColor | ResourceColor | 是  | 设置行内代码的颜色，默认："#F4271C" 。 |

**使用示例**

``` javascript
this.controller.setInlineCodeColor("#F4271C")
```

### setInlineCodeBackgroundColor

setInlineCodeBackgroundColor(inlineCodeBackgroundColor: ResourceColor)

设置行内代码背景颜色。

**参数**

| 参数名                       | 类型            | 必填 | 说明                           |
|---------------------------|---------------|----|------------------------------|
| inlineCodeBackgroundColor | ResourceColor | 是  | 设置行内代码的背景颜色，默认："#0eff0000" 。 |

**使用示例**

``` javascript
this.controller.setInlineCodeBackgroundColor("#0eff0000")
```

### setInlineCodeBackgroundRadius

setInlineCodeBackgroundRadius(radius: Dimension)

设置行内代码背景圆角。

**参数**

| 参数名                           | 类型     | 必填 | 说明                   |
|-------------------------------|--------|----|----------------------|
| setInlineCodeBackgroundRadius | radius | 是  | 设置行内代码的背景颜色，默认：5vp 。 |

**使用示例**

``` javascript
this.controller.setInlineCodeBackgroundRadius(5)
```

### setQuoteBorderRadius `new 3.2.2+`

setQuoteBorderRadius(radius: ResourceStr | number)

设置引用块圆角。

**参数**

| 参数名    | 类型                    | 必填 | 说明                |
|--------|-----------------------|----|-------------------|
| radius | ResourceStr \| number | 是  | 设置引用块圆角，默认：14vp 。 |

**使用示例**

``` javascript
this.controller.setQuoteBorderRadius(14)
```

### setQuoteBorderWidth `new 3.2.2+`

setQuoteBorderWidth(size: ResourceStr | number)

设置引用块左边宽度。

**参数**

| 参数名  | 类型                    | 必填 | 说明                 |
|------|-----------------------|----|--------------------|
| size | ResourceStr \| number | 是  | 设置引用块左边宽度，默认：5vp 。 |

**使用示例**

``` javascript
this.controller.setQuoteBorderWidth(5)
```

### setQuoteBorderColor

setQuoteBorderColor(quoteBorderColor: ResourceColor)

设置引用块左边颜色。

**参数**

| 参数名              | 类型            | 必填 | 说明                        |
|------------------|---------------|----|---------------------------|
| quoteBorderColor | ResourceColor | 是  | 设置引用块左边的颜色，默认："#F4271C" 。 |

**使用示例**

``` javascript
this.controller.setQuoteBorderColor("#F4271C")
```

### setQuoteTextColor `new 3.4.3+`

setQuoteTextColor(color: ResourceColor)

设置引用块文本颜色。

**参数**

| 参数名   | 类型            | 必填 | 说明                       |
|-------|---------------|----|--------------------------|
| color | ResourceColor | 是  | 设置引用块文本颜色，默认："#666666" 。 |

**使用示例**

``` javascript
this.controller.setQuoteTextColor("#666666")
```

### setQuoteBackgroundColor

setQuoteBackgroundColor(quoteBackgroundColor: ResourceColor)

设置引用块背景颜色。

**参数**

| 参数名                  | 类型            | 必填 | 说明                          |
|----------------------|---------------|----|-----------------------------|
| quoteBackgroundColor | ResourceColor | 是  | 设置引用块的背景颜色，默认："#ccf5f7fa" 。 |

**使用示例**

``` javascript
this.controller.setQuoteBackgroundColor("#ccf5f7fa")
```

### setQuotePadding `new 3.3.0+`

setQuotePadding(padding: Padding | Length | LocalizedPadding)

设置引用块内边距。

**参数**

| 参数名     | 类型                                    | 必填 | 说明                                                     |
|---------|---------------------------------------|----|--------------------------------------------------------|
| padding | Padding \| Length \| LocalizedPadding | 是  | 设置引用块内边距，默认：{left: 10, top: 8, right: 8, bottom: 10} 。 |

**使用示例**

``` javascript
this.controller.setQuotePadding(12)
```

### setCodeBlockBorderRadius `new 3.2.2+`

setCodeBlockBorderRadius(radius: number | ResourceStr)

设置代码块圆角。

**参数**

| 参数名    | 类型                    | 必填 | 说明                |
|--------|-----------------------|----|-------------------|
| radius | ResourceStr \| number | 是  | 设置代码块圆角，默认：14vp 。 |

**使用示例**

``` javascript
this.controller.setCodeBlockBorderRadius(14)
```

### setCodeBlockTheme

setCodeBlockTheme(codeBlockTheme: CodeTheme)

设置代码块主题。

**参数**

| 参数名            | 类型                | 必填 | 说明                    |
|----------------|-------------------|----|-----------------------|
| codeBlockTheme | "light" \| "dark" | 是  | 设置代码块的主题，默认："light" 。 |

**使用示例**

``` javascript
this.controller.setCodeBlockTheme("light")
```

### setCodeBlockIdxState

setCodeBlockIdxState(codeBlockIdxState: boolean)

设置代码块索引展示状态。

**参数**

| 参数名               | 类型      | 必填 | 说明                      |
|-------------------|---------|----|-------------------------|
| codeBlockIdxState | boolean | 是  | 设置代码块索引的展示状态，默认：false 。 |

**使用示例**

``` javascript
this.controller.setCodeBlockIdxState(false)
```

### setCodeBlockActionAreaVisible `new 3.4.6+`

setCodeBlockActionAreaVisible(visible: boolean)

设置普通代码块整个顶部操作区是否展示。操作区包含语言名称、复制按钮和放大按钮；隐藏后不会保留空白高度。
语言为 `html`、`htm` 或 `mermaid` 的代码块始终保留顶部操作区，不受该接口影响。

**参数**

| 参数名     | 类型      | 必填 | 说明                              |
|---------|---------|----|---------------------------------|
| visible | boolean | 是  | 是否展示普通代码块顶部操作区，默认：true。 |

**使用示例**

``` javascript
this.controller.setCodeBlockActionAreaVisible(false)

// 恢复展示
this.controller.setCodeBlockActionAreaVisible(true)
```

### setCodeBlockAutoCollapseEnable `new 3.4.4+`

setCodeBlockAutoCollapseEnable(enable: boolean)

设置代码块是否自动折叠。开启后，超过折叠阈值的代码块会默认折叠，并展示展开按钮。

**参数**

| 参数名    | 类型      | 必填 | 说明                    |
|--------|---------|----|-----------------------|
| enable | boolean | 是  | 是否开启代码块自动折叠，默认：true 。 |

**使用示例**

``` javascript
this.controller.setCodeBlockAutoCollapseEnable(true)
```

### setCodeBlockAutoCollapseThreshold `new 3.4.4+`

setCodeBlockAutoCollapseThreshold(threshold: number)

设置代码块自动折叠阈值。仅在 `setCodeBlockAutoCollapseEnable(true)` 后生效；当代码块行数超过该阈值时会默认折叠。

**参数**

| 参数名       | 类型     | 必填 | 说明                       |
|-----------|--------|----|--------------------------|
| threshold | number | 是  | 自动折叠阈值，默认：10。非法值会回退为 10。 |

**使用示例**

``` javascript
this.controller
  .setCodeBlockAutoCollapseEnable(true)
  .setCodeBlockAutoCollapseThreshold(20)
```

### setMermaidEnable `new 3.4.3+`

setMermaidEnable(enable: boolean)

设置是否将语言为 `mermaid` 的代码块渲染为 Mermaid 图表预览。

**参数**

| 参数名    | 类型      | 必填 | 说明                          |
|--------|---------|----|-----------------------------|
| enable | boolean | 是  | 是否开启 Mermaid 图表渲染，默认：true 。 |

**使用示例**

``` javascript
this.controller.setMermaidEnable(true)
```

### setMermaidTheme `new 3.4.3+`

setMermaidTheme(theme: "light" | "dark")

设置 Mermaid 图表深浅色主题。

**参数**

| 参数名   | 类型                | 必填 | 说明                           |
|-------|-------------------|----|------------------------------|
| theme | "light" \| "dark" | 是  | 设置 Mermaid 图表主题，默认："light" 。 |

**使用示例**

``` javascript
this.controller.setMermaidTheme("dark")
```

### setMermaidSecurityLevel `new 3.4.3+`

setMermaidSecurityLevel(securityLevel: "strict" | "loose" | "antiscript" | "sandbox")

设置 Mermaid 预览的安全级别。

**参数**

| 参数名           | 类型                                               | 必填 | 说明                              |
|---------------|--------------------------------------------------|----|---------------------------------|
| securityLevel | "strict" \| "loose" \| "antiscript" \| "sandbox" | 是  | 设置 Mermaid 渲染安全级别，默认："strict" 。 |

**使用示例**

``` javascript
this.controller.setMermaidSecurityLevel("strict")
```

### setHtmlPreviewEnable `new 3.4.4+`

setHtmlPreviewEnable(enable: boolean)

设置是否开启 HTML 代码块预览。开启后，语言为 `html` 或 `htm` 的代码块会渲染为 HTML 预览。

**参数**

| 参数名    | 类型      | 必填 | 说明                         |
|--------|---------|----|----------------------------|
| enable | boolean | 是  | 是否开启 HTML 代码块预览，默认：false 。 |

**使用示例**

``` javascript
this.controller.setHtmlPreviewEnable(true)
```

### setHtmlPreviewJavaScriptEnable `new 3.4.4+`

setHtmlPreviewJavaScriptEnable(enable: boolean)

设置 HTML 代码块预览是否允许执行 JavaScript。该开关只影响 HTML 预览，Mermaid 预览不受影响。

**参数**

| 参数名    | 类型      | 必填 | 说明                                     |
|--------|---------|----|----------------------------------------|
| enable | boolean | 是  | HTML 代码块预览是否允许执行 JavaScript，默认：false 。 |

**使用示例**

``` javascript
this.controller
  .setHtmlPreviewEnable(true)
  .setHtmlPreviewJavaScriptEnable(false)
```

### setWebPreviewPoolEnable `new 3.4.4+`

setWebPreviewPoolEnable(enable: boolean)

设置 Mermaid / HTML 内联预览是否复用 ArkWeb 预览池。开启后会预热少量 Web 组件，并在 Mermaid / HTML 预览之间复用，减少频繁创建
Web 组件带来的开销。

**参数**

| 参数名    | 类型      | 必填 | 说明                        |
|--------|---------|----|---------------------------|
| enable | boolean | 是  | 是否开启 ArkWeb 预览池，默认：true 。 |

**使用示例**

``` javascript
this.controller.setWebPreviewPoolEnable(true)
```

### setWebPreviewPoolSize `new 3.4.4+`

setWebPreviewPoolSize(initialSize: number, maxSize: number, idleRetain: number)

设置 ArkWeb 预览池大小。

**参数**

| 参数名         | 类型     | 必填 | 说明                |
|-------------|--------|----|-------------------|
| initialSize | number | 是  | 预热 Web 组件数量，默认：2。 |
| maxSize     | number | 是  | 预览池最大动态扩容数量，默认：4。 |
| idleRetain  | number | 是  | 长期保留的空闲槽数量，默认：2。  |

**使用示例**

``` javascript
this.controller
  .setWebPreviewPoolEnable(true)
  .setWebPreviewPoolSize(2, 4, 2)
```

### setCodeCopyListener

setCodeCopyListener(event: (text: string) => void)

设置代码块点击复制的监听回调，因隐私政策调整，请通过该接口注册代码块复制监听，并自行实现代码块的复制处理逻辑。详细可参阅文章：[代码块复制操作指导](https://developer.huawei.com/consumer/cn/blog/topic/03198432164313012)。

**参数**

| 参数名   | 类型                     | 必填 | 说明                                       |
|-------|------------------------|----|------------------------------------------|
| event | (text: string) => void | 是  | 设置代码块点击复制的监听回调，默认：(text: string) => {} 。 |

**使用示例**

``` javascript
this.controller.setCodeCopyListener((text) => {
    // Create clipboard content object
    const pasteboardData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, text);
    // Get system clipboard object
    const systemPasteboard = pasteboard.getSystemPasteboard();
    systemPasteboard.setData(pasteboardData) // Put data into clipboard
      .then(() => {
        promptAction.showToast({ message: 'copy success.' });
      })
})
```

### setImageBorderRadius `new 3.2.2+`

setImageBorderRadius(radius: number | ResourceStr)

设置图片圆角。

**参数**

| 参数名    | 类型                    | 必填 | 说明               |
|--------|-----------------------|----|------------------|
| radius | ResourceStr \| number | 是  | 设置图片圆角，默认：14vp 。 |

**使用示例**

``` javascript
this.controller.setImageBorderRadius(14)
```

### setImageWidth

setImageWidth(imageWidth: ResourceStr | number | null)

设置图片宽度。

**参数**

| 参数名        | 类型                            | 必填 | 说明                  |
|------------|-------------------------------|----|---------------------|
| imageWidth | ResourceStr \| number \| null | 是  | 设置图片的宽度，默认："100%" 。 |

**使用示例**

``` javascript
this.controller.setImageWidth("100%")
```

### setImageMaxWidth

setImageMaxWidth(imageMaxWidth: ResourceStr | number | null)

设置图片最大宽度。

**参数**

| 参数名           | 类型                            | 必填 | 说明                  |
|---------------|-------------------------------|----|---------------------|
| imageMaxWidth | ResourceStr \| number \| null | 是  | 设置图片的最大宽度，默认：null 。 |

**使用示例**

``` javascript
this.controller.setImageMaxWidth(null)
```

### setImageHeight

setImageHeight(imageHeight: ResourceStr | number | null)

设置图片高度。

**参数**

| 参数名         | 类型                            | 必填 | 说明                |
|-------------|-------------------------------|----|-------------------|
| imageHeight | ResourceStr \| number \| null | 是  | 设置图片的高度，默认：null 。 |

**使用示例**

``` javascript
this.controller.setImageHeight(null)
```

### setImageMaxHeight

setImageMaxHeight(imageMaxHeight: ResourceStr | number | null)

设置图片最大高度。

**参数**

| 参数名            | 类型                            | 必填 | 说明                  |
|----------------|-------------------------------|----|---------------------|
| imageMaxHeight | ResourceStr \| number \| null | 是  | 设置图片的最大高度，默认：null 。 |

**使用示例**

``` javascript
this.controller.setImageMaxHeight(null)
```

### setImageClickListener

setImageClickListener(event: (src: string) => boolean)

设置图片点击监听回调，**return false 不拦截，return true 拦截**。

**参数**

| 参数名   | 类型                       | 必填 | 说明                                                 |
|-------|--------------------------|----|----------------------------------------------------|
| event | (src: string) => boolean | 是  | 设置图片的点击监听回调，默认：(src: string) => { return false } 。 |

**使用示例**

``` javascript
this.controller.setImageClickListener((src: string) => { 
    console.log("拦截跳转 src: " + src) // 图片地址
    promptAction.showToast({ message: src })
    return true
})
```

### setImageLoadProxy

setImageLoadProxy(event: (src: string) => string)

设置图片加载代理，回调图片加载前的 src ，返回值需返回处理后的 src 。

仅支持 http, https 协议的图片设置加载代理，$rawfile 本地资源图片不支持设置代理。

**参数**

| 参数名   | 类型                      | 必填 | 说明                                            |
|-------|-------------------------|----|-----------------------------------------------|
| event | (src: string) => string | 是  | 设置图片加载代理，默认：(src: string) => { return src } 。 |

**使用示例**

``` javascript
this.controller.setImageLoadProxy((src) => {
  console.log("imageLoadSrc > " + src)
  // 在这里处理完整的图片 url 后 return 即可。
  src = "http://xxxx.example/" + src
  return src
})
```

### setHyperlinkTextColor

setHyperlinkTextColor(hyperlinkTextColor: ResourceColor)

设置超链接文字颜色。

**参数**

| 参数名                | 类型            | 必填 | 说明                        |
|--------------------|---------------|----|---------------------------|
| hyperlinkTextColor | ResourceColor | 是  | 设置超链接的文字颜色，默认："#0664EC" 。 |

**使用示例**

``` javascript
this.controller.setHyperlinkTextColor("#0664EC")
```

### setHyperlinkTextSize `new 3.2.2+`

setHyperlinkTextSize(size: ResourceStr | number)

设置超链接文字字号，不设置则跟随普通文本字号。

**参数**

| 参数名  | 类型                    | 必填 | 说明                            |
|------|-----------------------|----|-------------------------------|
| size | ResourceStr \| number | 是  | 设置超链接文字字号，默认：null（跟随普通文本字号） 。 |

**使用示例**

``` javascript
this.controller.setHyperlinkTextSize(12)
```

### setHyperlinkBackgroundColor

setHyperlinkBackgroundColor(color: ResourceColor)

设置超链接背景颜色。

**参数**

| 参数名   | 类型            | 必填 | 说明                                     |
|-------|---------------|----|----------------------------------------|
| color | ResourceColor | 是  | 设置行内代码的背景颜色，默认：Color.Transparent（透明） 。 |

**使用示例**

``` javascript
this.controller.setHyperlinkBackgroundColor("#0eff0000")
```

### setHyperlinkBackgroundRadius

setHyperlinkBackgroundRadius(radius: Dimension)

设置超链接背景圆角。

**参数**

| 参数名                          | 类型     | 必填 | 说明                   |
|------------------------------|--------|----|----------------------|
| setHyperlinkBackgroundRadius | radius | 是  | 设置行内代码的背景颜色，默认：5vp 。 |

**使用示例**

``` javascript
this.controller.setHyperlinkBackgroundRadius(5)
```

### setHyperlinkUnderlineState

setHyperlinkUnderlineState(hyperlinkUnderlineState: boolean)

设置超链接下划线展示状态。

**参数**

| 参数名                     | 类型      | 必填 | 说明                          |
|-------------------------|---------|----|-----------------------------|
| hyperlinkUnderlineState | boolean | 是  | 设置超链接下划线的展示状态，默认：false 不展示。 |

**使用示例**

``` javascript
this.controller.setHyperlinkUnderlineState(false)
```

### setHyperlinkClickListener

setHyperlinkClickListener(event: (title: string, src: string) => boolean)

设置超链接点击监听回调，**return false 不拦截，return true 拦截**。

**参数**

| 参数名   | 类型                                      | 必填 | 说明                                                  |
|-------|-----------------------------------------|----|-----------------------------------------------------|
| event | (title: string, src: string) => boolean | 是  | 设置超链接的点击监听回调，默认：(src: string) => { return false } 。 |

**使用示例**

``` javascript
this.controller.setHyperlinkClickListener((src: string) => { 
    console.log("拦截跳转 title: " + title) // 标题
    console.log("拦截跳转 src: " + src) // 网页地址
    promptAction.showToast({ message: title + "\n" + src })
    return true
})
```

### setTableAlign `new 3.2.2+`

setTableAlign(flexAlign: FlexAlign)

设置表格在屏幕上的屏幕对齐方式。

**参数**

| 参数名       | 类型        | 必填 | 说明                             |
|-----------|-----------|----|--------------------------------|
| flexAlign | FlexAlign | 是  | 设置表格屏幕对齐方式，默认：FlexAlign.Start。 |

**使用示例**

``` javascript
this.controller.setTableAlign(FlexAlign.Center)
```

### setTableBorderRadius `new 3.2.2+`

setTableBorderRadius(radius: number | ResourceStr)

设置表格圆角。

**参数**

| 参数名    | 类型                    | 必填 | 说明               |
|--------|-----------------------|----|------------------|
| radius | ResourceStr \| number | 是  | 设置表格圆角，默认：14vp 。 |

**使用示例**

``` javascript
this.controller.setTableBorderRadius(14)
```

### setTableOuterBorderColor `new 3.2.2+`

setTableOuterBorderColor(color: ResourceColor)

设置表格外边框颜色。

**参数**

| 参数名   | 类型            | 必填 | 说明                                  |
|-------|---------------|----|-------------------------------------|
| color | ResourceColor | 是  | 设置表格外边框颜色，默认：Color.Transparent（透明）。 |

**使用示例**

``` javascript
this.controller.setTableOuterBorderColor(Color.Red)
```

### setTableOuterBorderWidth `new 3.2.2+`

setTableOuterBorderWidth(width: ResourceStr | number)

设置表格外边框宽度。

**参数**

| 参数名   | 类型                    | 必填 | 说明                 |
|-------|-----------------------|----|--------------------|
| width | ResourceStr \| number | 是  | 设置表格外边框宽度，默认：1vp 。 |

**使用示例**

``` javascript
this.controller.setTableOuterBorderWidth(2)
```

### setTableInnerBorderColor `new 3.2.2+`

setTableInnerBorderColor(color: ResourceColor)

设置表格内边框颜色。

**参数**

| 参数名   | 类型            | 必填 | 说明                                  |
|-------|---------------|----|-------------------------------------|
| color | ResourceColor | 是  | 设置表格内边框颜色，默认：Color.Transparent（透明）。 |

**使用示例**

``` javascript
this.controller.setTableInnerBorderColor(Color.Red)
```

### setTableInnerBorderWidth `new 3.2.2+`

setTableInnerBorderWidth(width: ResourceStr | number)

设置表格内边框宽度。

**参数**

| 参数名   | 类型                    | 必填 | 说明                 |
|-------|-----------------------|----|--------------------|
| width | ResourceStr \| number | 是  | 设置表格内边框宽度，默认：1vp 。 |

**使用示例**

``` javascript
this.controller.setTableInnerBorderWidth(2)
```

### setTableBackgroundColor

setTableBackgroundColor(tableBackgroundColor: ResourceColor)

设置表格背景色。

**参数**

| 参数名                  | 类型            | 必填 | 说明                      |
|----------------------|---------------|----|-------------------------|
| tableBackgroundColor | ResourceColor | 是  | 设置表格的背景色，默认："#FFFFFF" 。 |

**使用示例**

``` javascript
this.controller.setTableBackgroundColor("#FFFFFF")
```

### setTableTitleTextColor `new 3.4.2+`

setTableTitleTextColor(tableTitleTextColor: ResourceColor)

设置表格表头文本颜色。

**参数**

| 参数名                 | 类型            | 必填 | 说明                           |
|---------------------|---------------|----|------------------------------|
| tableTitleTextColor | ResourceColor | 是  | 设置表格表头的文本颜色，默认："#e61f1f39" 。 |

**使用示例**

``` javascript
this.controller.setTableTitleTextColor("#e61f1f39")
```

### setTableInterleaveTextColor `new 3.4.2+`

setTableInterleaveTextColor(tableInterleaveTextColor: ResourceColor)

设置表格错行的文本颜色。

**参数**

| 参数名                      | 类型            | 必填 | 说明                           |
|--------------------------|---------------|----|------------------------------|
| tableInterleaveTextColor | ResourceColor | 是  | 设置表格错行的文本颜色，默认："#e61f1f39" 。 |

**使用示例**

``` javascript
this.controller.setTableInterleaveTextColor("#e61f1f39")
```

### setTableNormalTextColor `new 3.4.2+`

setTableNormalTextColor(tableNormalTextColor: ResourceColor)

设置表格非错行的文本颜色。

**参数**

| 参数名                  | 类型            | 必填 | 说明                            |
|----------------------|---------------|----|-------------------------------|
| tableNormalTextColor | ResourceColor | 是  | 设置表格非错行的文本颜色，默认："#e61f1f39" 。 |

**使用示例**

``` javascript
this.controller.setTableNormalTextColor("#e61f1f39")
```

### setTableTitleBackgroundColor

setTableTitleBackgroundColor(tableTitleBackgroundColor: ResourceColor)

设置表格表头背景色。

**参数**

| 参数名                       | 类型            | 必填 | 说明                        |
|---------------------------|---------------|----|---------------------------|
| tableTitleBackgroundColor | ResourceColor | 是  | 设置表格表头的背景色，默认："#F5F7FA" 。 |

**使用示例**

``` javascript
this.controller.setTableTitleBackgroundColor("#F5F7FA")
```

### setTableInterleaveBackgroundColor

setTableInterleaveBackgroundColor(tableInterleaveBackgroundColor: ResourceColor)

设置表格错行背景色。

**参数**

| 参数名                            | 类型            | 必填 | 说明                          |
|--------------------------------|---------------|----|-----------------------------|
| tableInterleaveBackgroundColor | ResourceColor | 是  | 设置表格错行的背景色，默认："#80f5f7fa" 。 |

**使用示例**

``` javascript
this.controller.setTableInterleaveBackgroundColor("#80f5f7fa")
```

### setTableCopyClickListener `new 3.4.6+`

setTableCopyClickListener(listener?: (rawTableMarkdown: string) => void)

设置表格复制按钮点击监听，设置后即展示复制图标，点击只返回当前表格的原始 Markdown。组件不直接执行剪贴板写入，具体操作由业务自行实现。

**参数**

| 参数名      | 类型                                                        | 必填 | 说明                                      |
|----------|-----------------------------------------------------------|----|-----------------------------------------|
| listener | ((rawTableMarkdown: string) => void) \| undefined         | 否  | 返回当前表格的原始 Markdown；默认 `undefined`，按钮不显示。 |

**使用示例**

``` javascript
this.controller.setTableCopyClickListener((rawTableMarkdown: string) => {
  console.info("复制表格：" + rawTableMarkdown)
})
```

### setTableDownloadClickListener `new 3.4.6+`

setTableDownloadClickListener(listener?: (rawTableMarkdown: string) => void)

设置表格下载按钮点击监听，设置后即展示下载图标，点击只返回当前表格的原始 Markdown。组件不直接执行文件下载，具体操作由业务自行实现。

**参数**

| 参数名      | 类型                                                        | 必填 | 说明                                      |
|----------|-----------------------------------------------------------|----|-----------------------------------------|
| listener | ((rawTableMarkdown: string) => void) \| undefined         | 否  | 返回当前表格的原始 Markdown；默认 `undefined`，按钮不显示。 |

**使用示例**

``` javascript
this.controller.setTableDownloadClickListener((rawTableMarkdown: string) => {
  console.info("下载表格：" + rawTableMarkdown)
})
```

### setTableExpandClickListener `new 3.4.6+`

setTableExpandClickListener(listener?: (rawTableMarkdown: string) => void)

设置表格放大按钮点击监听，设置后即展示放大图标，点击只返回当前表格的原始 Markdown。组件不直接展示放大弹窗，具体操作由业务自行实现。

**参数**

| 参数名      | 类型                                                        | 必填 | 说明                                      |
|----------|-----------------------------------------------------------|----|-----------------------------------------|
| listener | ((rawTableMarkdown: string) => void) \| undefined         | 否  | 返回当前表格的原始 Markdown；默认 `undefined`，按钮不显示。 |

**使用示例**

``` javascript
this.controller.setTableExpandClickListener((rawTableMarkdown: string) => {
  console.info("放大表格：" + rawTableMarkdown)
})
```

### setTableActionBackgroundColor `new 3.4.6+`

setTableActionBackgroundColor(tableActionBackgroundColor: ResourceColor)

设置表格操作区背景色。未调用本接口时，操作区背景色动态跟随表格错行背景色；调用后使用指定颜色。

**参数**

| 参数名                         | 类型            | 必填 | 说明          |
|-----------------------------|---------------|----|-------------|
| tableActionBackgroundColor  | ResourceColor | 是  | 设置表格操作区背景色。 |

**使用示例**

``` javascript
this.controller.setTableActionBackgroundColor("#80f5f7fa")
```

### setTableActionIconColor `new 3.4.6+`

setTableActionIconColor(iconColor: string)

统一设置表格复制、下载和放大图标的滤镜颜色。仅支持 `#RRGGBB`、`RRGGBB` 或空字符串；未调用本接口或传入空字符串时保留图标原始颜色。

**参数**

| 参数名       | 类型     | 必填 | 说明                                      |
|-----------|--------|----|-----------------------------------------|
| iconColor | string | 是  | 设置三个操作图标的滤镜颜色；传入空字符串时恢复图标原始颜色。 |

**使用示例**

``` javascript
this.controller.setTableActionIconColor("#1A1A33")

// 恢复图标原始颜色
this.controller.setTableActionIconColor("")
```

**完整示例**

``` javascript
this.controller
  .setTableCopyClickListener((rawTableMarkdown: string) => {
    console.info("复制表格：" + rawTableMarkdown)
  })
  .setTableDownloadClickListener((rawTableMarkdown: string) => {
    console.info("下载表格：" + rawTableMarkdown)
  })
  .setTableExpandClickListener((rawTableMarkdown: string) => {
    console.info("放大表格：" + rawTableMarkdown)
  })
  .setTableActionBackgroundColor("#80f5f7fa")
  .setTableActionIconColor("#1A1A33")

// 取消复制监听并隐藏复制按钮
this.controller.setTableCopyClickListener(undefined)
```

### setTodoSelectedColor

setTodoSelectedColor(todoSelectedColor: ResourceColor)

设置任务列表选中颜色。

**参数**

| 参数名               | 类型            | 必填 | 说明                         |
|-------------------|---------------|----|----------------------------|
| todoSelectedColor | ResourceColor | 是  | 设置任务列表的选中颜色，默认："#0A59F7" 。 |

**使用示例**

``` javascript
this.controller.setTodoSelectedColor("#0A59F7")
```

### setTodoSelectSize

setTodoSelectSize(todoSelectSize: ResourceStr | number)

设置任务列表选项大小。

**参数**

| 参数名            | 类型                    | 必填 | 说明                    |
|----------------|-----------------------|----|-----------------------|
| todoSelectSize | ResourceStr \| number | 是  | 设置任务列表选项的大小，默认：16vp 。 |

**使用示例**

``` javascript
this.controller.setTodoSelectSize(16)
```

### setUlPointSize `new 3.2.2+`

setUlPointSize(size: ResourceStr | number)

设置无序列表指示点大小。

**参数**

| 参数名  | 类型                    | 必填 | 说明                   |
|------|-----------------------|----|----------------------|
| size | ResourceStr \| number | 是  | 设置无序列表指示点大小，默认：5vp 。 |

**使用示例**

``` javascript
this.controller.setUlPointSize(5)
```

### setUlPointColor `new 3.2.2+`

setUlPointColor(color: ResourceColor)

设置无序列表指示点颜色，不设置默认跟随字体颜色。

**参数**

| 参数名   | 类型            | 必填 | 说明                    |
|-------|---------------|----|-----------------------|
| color | ResourceColor | 是  | 设置无序列表指示点大小，默认：null 。 |

**使用示例**

``` javascript
this.controller.setUlPointColor(Color.Red)
```

### setFootnoteTextColor

setFootnoteTextColor(footnoteTextColor: ResourceColor)

设置脚注文字颜色。

**参数**

| 参数名               | 类型            | 必填 | 说明                         |
|-------------------|---------------|----|----------------------------|
| footnoteTextColor | ResourceColor | 是  | 设置脚注的文字颜色，默认："#fffa460d" 。 |

**使用示例**

``` javascript
this.controller.setFootnoteTextColor("#fffa460d")
```

### setLineColor

setLineColor(lineColor: ResourceColor)

设置分割线颜色。

**参数**

| 参数名       | 类型            | 必填 | 说明                   |
|-----------|---------------|----|----------------------|
| lineColor | ResourceColor | 是  | 设置分割线的颜色，默认："#EEE" 。 |

**使用示例**

``` javascript
this.controller.setLineColor("#EEE")
```

### ~~setCopyOption~~ `deprecated 3.4.0`

setCopyOption(copyOption: CopyOptions)

设置剪贴板复制范围选项。从 3.4.0 版本开始，该接口不再维护，调用后不再生效，请使用 setTextSelectionEnable() 与
setTextSelectionEnable() 实现文本选择复制功能。

**参数**

| 参数名        | 类型          | 必填 | 说明                                     |
|------------|-------------|----|----------------------------------------|
| copyOption | CopyOptions | 是  | 剪贴板复制范围选项，默认：CopyOptions.LocalDevice 。 |

**使用示例**

``` javascript
this.controller.setCopyOption(CopyOptions.None)
```

### setBlockSpacing `new 3.3.0+`

setBlockSpacing(spacing: number | ResourceStr)

设置块级元素间距。

**参数**

| 参数名     | 类型     | 必填          | 说明 |
|---------|--------|-------------|----|
| spacing | number | ResourceStr | 是  | 设置块级元素间距，默认：10vp 。 |

**使用示例**

``` javascript
this.controller.setBlockSpacing(10)
```

### setTextSelectionEnable `new 3.4.0+`

setTextSelectionEnable(enable: boolean)

设置是否开启跨多个 `Text` 组件的长按选择能力。默认关闭；开启后，可通过长按 Markdown 文本并拖拽两侧光标的方式选择跨段落内容。

**参数**

| 参数名    | 类型      | 必填 | 说明                         |
|--------|---------|----|----------------------------|
| enable | boolean | 是  | 是否开启跨 Text 文本选择，默认：false 。 |

**使用示例**

``` javascript
this.controller.setTextSelectionEnable(true)
```

### setTextSelectionCopyListener `new 3.4.0+`

setTextSelectionCopyListener(event: (text: string) => void)

设置跨 Text 文本选择后的复制监听。因系统剪贴板涉及业务权限控制，组件只回传最终选中的文本内容，由业务侧决定是否写入剪贴板。

**参数**

| 参数名   | 类型                     | 必填 | 说明                                                                       |
|-------|------------------------|----|--------------------------------------------------------------------------|
| event | (text: string) => void | 是  | 设置跨 Text 选中复制监听；未设置时默认弹出提示："复制失败，请检查 setTextSelectionCopyListener 接口实现"。 |

**使用示例**

``` javascript
this.controller
  .setTextSelectionEnable(true)
  .setTextSelectionCopyListener((text) => {
    const pasteboardData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, text)
    const systemPasteboard = pasteboard.getSystemPasteboard()
    systemPasteboard.setData(pasteboardData)
      .then(() => {
        promptAction.showToast({ message: 'copy success.' })
      })
  })
```

### setTextSelectionActionItems `new 3.4.4+`

setTextSelectionActionItems(items: TextSelectionActionItem[])

设置跨 Text 文本选择后的操作栏按钮。不设置或传入空数组时，使用默认操作：「复制 / 全选 / 取消」。

**参数**

| 参数名   | 类型                        | 必填 | 说明            |
|-------|---------------------------|----|---------------|
| items | TextSelectionActionItem[] | 是  | 自定义选区操作栏按钮数组。 |

**TextSelectionActionItem**

| 字段        | 类型                                            | 说明         |
|-----------|-----------------------------------------------|------------|
| title     | string                                        | 按钮文案。      |
| onClick   | (context: TextSelectionActionContext) => void | 点击按钮回调。    |
| fontColor | ResourceColor                                 | 按钮文字颜色。可选。 |

**TextSelectionActionContext**

| 字段           | 类型         | 说明         |
|--------------|------------|------------|
| selectedText | string     | 当前选中的文本内容。 |
| copy         | () => void | 执行默认复制动作。  |
| selectAll    | () => void | 选中全部可选文本。  |
| clear        | () => void | 清除当前选区。    |

**使用示例**

``` javascript
import { TextSelectionActionItem } from '@luvi/lv-markdown-in'

this.controller
  .setTextSelectionEnable(true)
  .setTextSelectionActionItems([
    new TextSelectionActionItem('复制', (context) => {
      context.copy()
    }),
    new TextSelectionActionItem('全选', (context) => {
      context.selectAll()
    }),
    new TextSelectionActionItem('取消', (context) => {
      context.clear()
    }, '#666666')
  ])
```

### clearTextSelection `new 3.4.7+`

clearTextSelection(): MarkdownController

主动清除当前 Controller 绑定 Markdown 实例的文本选区、高亮、拖拽手柄和内部操作栏。接口返回当前 `MarkdownController`，支持链式调用。

通过 `setLongPressMenuListener()` 创建的业务弹窗不由组件管理，点击外部区域时应先关闭业务弹窗状态，再调用本接口退出组件选区。

**使用示例**

``` javascript
// 页面外部区域点击事件
this.menuVisible = false
this.controller.clearTextSelection()
```

### setLongPressMenuEnable `new 3.4.0+`

setLongPressMenuEnable(enable: boolean)

设置是否开启长按菜单模式。开启后，长按 Markdown 文本时不会立即进入选区，而是通过 `setLongPressMenuListener`
回传按压点、段落文本和选取动作，由业务侧自行渲染菜单。

**参数**

| 参数名    | 类型      | 必填 | 说明                    |
|--------|---------|----|-----------------------|
| enable | boolean | 是  | 是否开启长按菜单模式，默认：false 。 |

**使用示例**

``` javascript
this.controller
  .setTextSelectionEnable(true)
  .setLongPressMenuEnable(true)
```

### setLongPressMenuListener `new 3.4.0+`

setLongPressMenuListener(event: (info: LongPressMenuInfo) => void)

设置长按菜单事件回调。回调参数 `LongPressMenuInfo` 携带长按位置、当前段落文本与选取动作，业务侧可基于这些信息自行渲染浮层菜单。

**LongPressMenuInfo**

| 字段               | 类型                                      | 说明                      |
|------------------|-----------------------------------------|-------------------------|
| blockId          | string                                  | 长按命中的文本块 ID。            |
| paragraphText    | string                                  | 长按所在段落的完整可复制文本。         |
| globalX          | number                                  | 长按点窗口 X 坐标，单位 vp。       |
| globalY          | number                                  | 长按点窗口 Y 坐标，单位 vp。       |
| selectWholeBlock | (type?: LongPressSelectionType) => void | 触发选区动作；无参调用默认使用 CUSTOM。 |

`selectWholeBlock(type?)` 支持三种选取类型：

| 类型                               | 说明                                  |
|----------------------------------|-------------------------------------|
| LongPressSelectionType.ALL       | 选中当前 Markdown 组件内全部可选文本。            |
| LongPressSelectionType.PARAGRAPH | 选中长按所在段落。                           |
| LongPressSelectionType.CUSTOM    | 从长按位置附近开始选中，显示手柄后可继续拖拽；无参调用默认使用该类型。 |

**使用示例**

``` javascript
import { LongPressMenuInfo, LongPressSelectionType } from '@luvi/lv-markdown-in'

this.controller
  .setTextSelectionEnable(true)
  .setLongPressMenuEnable(true)
  .setLongPressMenuListener((info: LongPressMenuInfo) => {
    // 复制当前段落
    this.controller.getTextSelectionCopyListener()(info.paragraphText)

    // 自定义选取：从长按位置附近开始选中；info.selectWholeBlock() 等价于该调用
    info.selectWholeBlock(LongPressSelectionType.CUSTOM)

    // 选中当前段落
    info.selectWholeBlock(LongPressSelectionType.PARAGRAPH)

    // 选中当前 Markdown 组件内全部可选文本
    info.selectWholeBlock(LongPressSelectionType.ALL)
  })
```

## 其他

有关 Markdown 的更多信息，请参阅 Markdown 官方教程 [Markdown](https://markdown.com.cn/) 。

使用过程中发现任何问题都可以提出 [Issues](https://gitee.com/luvi/lv-markdown-in/issues) 。

## 示例应用

欢迎前往应用市场下载：[Markdown代码工坊](https://appgallery.huawei.com/app/detail?id=com.markdown.lab)，直观体验
@luvi/lv-markdown-in 的渲染效果。

## 版权声明

本项目采用 MIT 开源协议，允许商用，修改，再分发。再分发时请注明原作者及原仓库地址。

## 隐私政策

我们非常重视您的个人信息和隐私保护，依据最新法律法规要求，更新并制定了：[关于 @luvi/lv-markdown-in 与隐私的声明](https://qxj.api.eeeo.cc:6655/lv-markdown-in/privacy-statement.html)
，在你使用本三方库前，请仔细阅读。
