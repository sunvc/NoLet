import { Markdown } from '../Index'

@Component
export struct Example {
  @State content: string = `
## 鸿蒙原生应用开发笔记
*鸿蒙原生*，意味着纯净与性能的平衡。
> 想让文字像在原生世界里呼吸，就得从渲染开始。
  `

  build() {
    Column() {
      Markdown({
        text: this.content, // content为文本内容
        mode: "text", // 默认 text 可省略
        callback: {
          // callback 可省略
          complete: () => {
            console.log("Markdown component load success.")
          },
          fail: (code: number, message: string) => {
            console.error("Markdown component load error. code: " + code + ", message: " + message)
          }
        }
      })
    }
    .width("100%")
    .height("100%")
  }
}