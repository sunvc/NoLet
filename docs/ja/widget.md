
## ウィジェット内で更新アドレスを設定する場合、GETリクエストメソッドは以下の形式のコンテンツを返す必要があります
```Json
{
  "large" : { // 大型ウィジェット
    "result" : [ 
      {
        "group" : "合計",
        "lines" : [
          13495
        ],
        "result" : [ // 固定されていないデータ長
          {
            "name" : "例1",
            "sort" : 0,
            "unity" : 1000,
            "value" : 10999
          },
          // ...  残りは上記と同様
        ],
        "sort" : 0,
        "type" : "pie"
      },
      {
        "group" : "例1",
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
           // ...  残りは上記と同様
        ],
        "sort" : 1
      },
       // ...  残りは上記と同様
    ],
    "subTitle" : "合計64件受信",
    "title" : "NoLet"
  },
  "lock" : { // ロック画面ウィジェット
    "subTitle" : "合計64件受信",
    "title" : "NoLet"
  },
  "medium" : { // 中型ウィジェット
    "result" : [ // 配列の長さは6
      {
        "name" : "合計",
        "value" : 18
      },
     // 配列の長さは6、残りの2つのデータは上記と同様
    ],
    "subTitle" : "合計64件受信",
    "title" : "NoLet"
  },
  "small" : {// 小型ウィジェット
    "result" : [  // 配列の長さは3
      {
        "name" : "合計",
        "value" : 18
      },
     // 配列の長さは3、残りの2つのデータは上記と同様
    ],
    "subTitle" : "合計64件受信",
    "title" : "NoLet"
  }
}


```