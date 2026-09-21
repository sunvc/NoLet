<div align="center">
<h1>formula</h1>
</div>

<p align="center">
<img alt="" src="https://img.shields.io/badge/release-v1.3.0-brightgreen" style="display: inline-block;" />
<img alt="" src="https://img.shields.io/badge/build-pass-brightgreen" style="display: inline-block;" />
<img alt="" src="https://img.shields.io/badge/cjc-v1.0.5-brightgreen" style="display: inline-block;" />
<img alt="" src="https://img.shields.io/badge/cjcov-NA-red" style="display: inline-block;" />
<img alt="" src="https://img.shields.io/badge/project-open-brightgreen" style="display: inline-block;" />
</p>

## 介绍

formula 主要目的是显示用 LaTeX 编写的数学公式。支持显示化学公式。

### 特性

* 解析生成数学公式数据

## 软件架构

### 源码目录

```shell
├─ har
├─ libs
└─ src
   └─ main
      ├─ cangjie
      ├─ ets
      └─ resources
```

- `har` har包目录
- `libs` so目录
- `src main cangjie` 仓颉源码目录
- `src main ets` ets源码目录
- `src main resources` 资源目录

### 接口说明

主要类和函数接口说明

```ets
/*
* 通过文本参数生成数学公式图片数组数据
*
* 参数 - latexMathTextString 数学公式文本内容
* 参数 - latexMathTextSize 数学公式文字大小 - 单位px
* 参数 - latexMathTextColor 数学公式文字颜色
* 参数 - latexMathBackGroupColor 数学公式背景颜色
* 参数 - latexMathColorFormat 数学公式图片格式
* 参数 - resPath 字体资源路径。 默认"/data/storage/el1/bundle/entry/resources/resfile/res"
*
* 返回值 - Promise<ArrayBuffer> 图片数组数据
*/
latexStringToImage(latexMathTextString: string, latexMathTextSize: number, latexMathTextColor: number, latexMathBackGroupColor: number, latexMathColorFormat: LatexMathColorFormat, resPath?: string): Promise<ArrayBuffer>

/**
 * 图片格式枚举
 */
enum LatexMathColorFormat {
  COLOR_FORMAT_RGB_565, // RGB_565
  COLOR_FORMAT_BGRA_8888 // BGRA_8888
}

/**
 * TeX解析结果码枚举
 */
enum TeXResultCode {
  Success = 0,              // 解析成功
  SyntaxError = 1,          // 语法错误
  InvalidMatrixError = 2,   // 无效矩阵错误
  InvalidDelimiterError = 3, // 无效分隔符错误
  TeXError = 4,             // TeX错误
  UnknownError = 99         // 未知错误
}

/**
 * TeX解析结果接口
 */
interface TeXParseResult {
  imageBytes: ArrayBuffer   // 图片字节数组（成功时有效）
  formula: string           // 原始公式文本
  resultCode: TeXResultCode // 结果码（Success表示成功）
  errorMessage: string      // 错误信息
}

/*
* 通过文本参数生成数学公式图片数组数据（带错误信息）
* 当公式解析失败时，返回详细的错误信息，包括结果码和错误描述
*
* 参数 - latexMathTextString 数学公式文本内容
* 参数 - latexMathTextSize 数学公式文字大小 - 单位px
* 参数 - latexMathTextColor 数学公式文字颜色
* 参数 - latexMathBackGroupColor 数学公式背景颜色
* 参数 - latexMathColorFormat 数学公式图片格式
* 参数 - resPath 字体资源路径。 默认"/data/storage/el1/bundle/entry/resources/resfile/res"
*
* 返回值 - Promise<TeXParseResult> 解析结果对象
*          - 成功时：resultCode=Success, imageBytes包含图片数据
*          - 失败时：resultCode为错误码, imageBytes为空, errorMessage包含错误详情
*/
latexStringToImageWithError(latexMathTextString: string, latexMathTextSize: number, latexMathTextColor: number, latexMathBackGroupColor: number, latexMathColorFormat: LatexMathColorFormat, resPath?: string): Promise<TeXParseResult>
```

## 使用说明

### ohpm安装使用

```cmd
ohpm install @cangjie-tpc/formula_hybrid
```

### 功能示例

#### 解析LaTeX公式

```ets
import { LatexMathColorFormat, latexStringToImage } from '@cangjie-tpc/formula_hybrid';
import { image } from '@kit.ImageKit';

@Entry
@Component
struct Index0 {
  str: string = "(a \\pm b)^2 = a^2 \\pm 2ab + b^2"
  @State pixelMap: image.PixelMap = undefined!;
  @State imageWidth: number = 0;
  @State imageHeight: number = 0;

  async aboutToAppear(): Promise<void> {
    try {
      // 通过接口解析数学公式获取数学公式图片数组数据
      let buf: ArrayBuffer = await latexStringToImage(this.str, fp2px(20), 0xFF000000, 0xFFFFFFFF,
        LatexMathColorFormat.COLOR_FORMAT_BGRA_8888)
      let imageSource = image.createImageSource(buf)
      // 图片pixelMap
      this.pixelMap = imageSource.createPixelMapSync()
      let size: Size = this.pixelMap.getImageInfoSync().size
      // 图片宽度
      this.imageWidth = px2vp(size.width)
      // 图片高度
      this.imageHeight = px2vp(size.height)
    } catch (e) {
    }
  }

  build() {
    Scroll() {
      Column() {
        Image(this.pixelMap)
          .objectFit(ImageFit.Contain)
          .width(this.imageWidth)
          .height(this.imageHeight)
          .margin({ top: 5, bottom: 5 })
      }
      .width('100%')
      .height('100%')
      .alignItems(HorizontalAlign.Start)
      .justifyContent(FlexAlign.Start)
    }
    .height('100%')
    .scrollBar(BarState.Off)
    .backgroundColor(Color.White)
  }
}
```

#### 执行结果如下

数学公式效果：

![img1](https://raw.gitcode.com/Cangjie-TPC/formula-ffi/raw/formula-ffi_hybrid_cangjie-plugin_5.1.1/doc/assets/img.png)

化学公式效果：

![img1](https://raw.gitcode.com/Cangjie-TPC/formula-ffi/raw/formula-ffi_hybrid_cangjie-plugin_5.1.1/doc/assets/img.jpg)

## 约束与限制

    在下述版本验证通过：    
        IDE: DevEco Studio 5.1.1 Release(Build Version:5.1.1.851)

1. `resPath`默认参数`"/data/storage/el1/bundle/entry/resources/resfile/res"`，如果修改`entry`命名，需要改成对应的`"/data/storage/el1/bundle/xxxx/resources/resfile/res"`。

2. unicode扩展支持的字符范围请参考[U1D400](https://www.unicode.org/charts/PDF/U1D400.pdf)。

3. NewCommand扩展包仅支持\def,\newenvironment,\renewenvironment

## 开源协议

本项目基于 [License](https://gitcode.com/Cangjie-TPC/formula-ffi/blob/formula-ffi_hybrid_cangjie-plugin_5.1.1/LICENSE)，请自由的享受和参与开源。

## 参与贡献

欢迎给我们提交PR，欢迎给我们提交Issue，欢迎参与任何形式的贡献。
