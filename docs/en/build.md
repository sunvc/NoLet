
*Thanks to the open source project [BARK](https://github.com/Finb/Bark)*
## Download Source Code
Download source code from GitHub [NoLet](https://github.com/sunvc/NoLets)

or
```sh
git clone https://github.com/sunvc/NoLets.git
```
## Configure Dependencies
- Golang 1.25+
- Go Mod (env GO111MODULE=on)
- Go Mod Proxy (env GOPROXY=https://goproxy.cn)

## Cross-compile for All Platforms
```sh
# Linux AMD version
CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o  main.go 
# Compile and run on local machine
go build -o  main.go 
# For other platforms, ask ChatGPT
```

