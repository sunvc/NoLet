
## 위젯 내 업데이트 주소 설정, 요청 방법 GET으로 다음 형식의 내용을 반환해야 함
```Json
{
  "large" : { // 대형 위젯
    "result" : [ 
      {
        "group" : "총계",
        "lines" : [
          13495
        ],
        "result" : [ // 고정되지 않은 데이터 길이
          {
            "name" : "예시1",
            "sort" : 0,
            "unity" : 1000,
            "value" : 10999
          },
          // ... 나머지는 위와 동일
        ],
        "sort" : 0,
        "type" : "pie"
      },
      {
        "group" : "예시1",
        "lines" : [
          1834
        ],
        "result" : [
          {
            "name" : "a",
            "sort" : 0,
            "unity" : 1000,
            "value" : 565
          },
           // ... 나머지는 위와 동일
        ],
        "sort" : 1
      },
       // ... 나머지는 위와 동일
    ],
    "subTitle" : "총 64개 수신됨",
    "title" : "NoLet"
  },
  "lock" : { // 잠금화면 위젯
    "subTitle" : "총 64개 수신됨",
    "title" : "NoLet"
  },
  "medium" : { // 중형 위젯
    "result" : [ // 배열 길이 6
      {
        "name" : "총계",
        "value" : 18
      },
     // 배열 길이 6, 나머지 2개 데이터는 위와 동일
    ],
    "subTitle" : "총 64개 수신됨",
    "title" : "NoLet"
  },
  "small" : {// 소형 위젯
    "result" : [  // 배열 길이 3
      {
        "name" : "총계",
        "value" : 18
      },
     // 배열 길이 3, 나머지 2개 데이터는 위와 동일
    ],
    "subTitle" : "총 64개 수신됨",
    "title" : "NoLet"
  }
}


```