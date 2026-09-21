# <center>html2md</center>

---

### 📚 简介

ArkTS 鸿蒙原生 html 常用标签转 markdown
语法三方库，目前支持的标签有（**不支持style内联样式
**）：`hr`、`br`、`span`、`text`、`mark`、`b`、`strong`、`i`、`dfn`、`em`、`u`、`del`、`blockquote`、`code`、`h1-h6`、`div`、`p`、`pre`、`a`、`img`、`ul`、`ol`、`li`。

### 🍺 html2md 安装

---
1.运行命令

``` shell
ohpm install @luvi/html2md
```

2.在项目中引入插件

``` javascript
import { html2md } from "@luvi/html2md"
```

3.在代码中使用

``` javascript
// html2mdResult为转换后的md文本
const html2mdResult = html2md("<b>加粗文本</b> <br> <p>这是一个段落，<i>斜体</i>可以包含在其中。</p>")
```

### 🍊 推荐配合使用 lv-markdown-in

markdown文本内容推荐使用 [@luvi/lv-markdown-in](https://ohpm.openharmony.cn/#/cn/detail/@luvi%2Flv-markdown-in)
markdown解析预览三方库`（若使用该库可省略html文本的转换，因为该库包含了html2md内容转换的解析）`。

### 🍺 版权声明

本项目采用 MIT 开源协议，允许商用，修改，再分发。