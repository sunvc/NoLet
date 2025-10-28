
## Set the update address in the widget, request method GET needs to return content in the following format
```Json
{
  "large" : { // Large widget
    "result" : [ 
      {
        "group" : "Total",
        "lines" : [
          13495
        ],
        "result" : [ // Variable data length
          {
            "name" : "Example1",
            "sort" : 0,
            "unity" : 1000,
            "value" : 10999
          },
          // ... More items with the same structure
        ],
        "sort" : 0,
        "type" : "pie"
      },
      {
        "group" : "Example1",
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
           // ... More items with the same structure
        ],
        "sort" : 1
      },
       // ... More items with the same structure
    ],
    "subTitle" : "Total received 64 items",
    "title" : "NoLet"
  },
  "lock" : { // Lock screen widget
    "subTitle" : "Total received 64 items",
    "title" : "NoLet"
  },
  "medium" : { // Medium widget
    "result" : [ // Array length 6
      {
        "name" : "Total",
        "value" : 18
      },
     // Array length 6, remaining 2 items with the same structure
    ],
    "subTitle" : "Total received 64 items",
    "title" : "NoLet"
  },
  "small" : {// Small widget
    "result" : [  // Array length 3
      {
        "name" : "Total",
        "value" : 18
      },
     // Array length 3, remaining 2 items with the same structure
    ],
    "subTitle" : "Total received 64 items",
    "title" : "NoLet"
  }
}


```