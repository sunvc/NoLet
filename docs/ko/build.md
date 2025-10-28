
*[BARK](https://github.com/Finb/Bark)의 오픈 소스 프로젝트에 감사드립니다*
## 소스 코드 다운로드
GitHub에서 소스 코드 다운로드 [NoLet](https://github.com/sunvc/NoLets)

또는
```sh
git clone https://github.com/sunvc/NoLets.git
```
## 의존성 구성
- Golang 1.25+
- Go Mod (env GO111MODULE=on)
- Go Mod Proxy (env GOPROXY=https://goproxy.cn)

## 모든 플랫폼용 크로스 컴파일
```sh
# linux amd 버전
CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o  main.go 
# 로컬에서 직접 컴파일 실행
go build -o  main.go 
# 다른 플랫폼은 ChatGpt에 문의
```

