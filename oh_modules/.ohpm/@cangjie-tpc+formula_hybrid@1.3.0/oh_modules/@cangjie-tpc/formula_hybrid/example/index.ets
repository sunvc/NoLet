import { LatexMathColorFormat, latexStringToImage } from '../Index';
import { image } from '@kit.ImageKit';

@Component
export struct Example  {
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