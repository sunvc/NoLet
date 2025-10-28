
*[BARK](https://github.com/Finb/Bark)のオープンソースプロジェクトに感謝します*
## ソースコードのダウンロード
GitHubからソースコードをダウンロード [NoLet](https://github.com/sunvc/NoLets)

または
```sh
git clone https://github.com/sunvc/NoLets.git
```
## 依存関係の設定
- Golang 1.25+
- Go Mod (env GO111MODULE=on)
- Go Mod Proxy (env GOPROXY=https://goproxy.cn)

## すべてのプラットフォーム向けのクロスコンパイル
```sh
# linux amd バージョン
CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o  main.go 
# ローカルマシンで直接コンパイルして実行
go build -o  main.go 
# その他のプラットフォームについては ChatGpt に問い合わせてください
```

