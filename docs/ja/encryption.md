*オープンソースの [BARK](https://github.com/Finb/Bark) プロジェクトに感謝します*

#### プッシュ暗号化とは

プッシュ暗号化は通知内容を保護する方法で、カスタムキーを用いて送信時と受信時に内容を暗号化/復号化します。<br>これにより、転送中に NoLet サーバーや Apple の APNs サーバーが内容を取得したり漏洩したりすることがありません。

#### カスタムキーの設定
1. アプリのホーム画面を開きます
2. 「プッシュ暗号化」を見つけて、暗号化設定を開きます
3. 暗号化アルゴリズムを選び、要件に従って KEY を入力し、完了をタップしてカスタムキーを保存します。`cipherNumber` はリストの順序を表し、既定値は `0` です。

#### 暗号化プッシュの送信
暗号化されたプッシュを送信するには、まず NoLet のリクエストパラメータを JSON 文字列に変換し、前もって設定したキーと選択したアルゴリズムで文字列を暗号化します。最後に、`nonce + ciphertext [+ tag]` を連結したデータを Base64 エンコードし、その文字列を `ciphertext` パラメータとしてサーバーへ送信します。<br><br>

以下は各種言語の例です。

**Python 例:**

```python
# ドキュメント: https://wiki.wzs.app/#/encryption
# Python デモ: AES でデータを暗号化し、サーバーへ送信
# pip3 install pycryptodome

import os
import json
import base64
import requests
from Crypto.Cipher import AES


# JSON データ
json_example = json.dumps({"title": "これは暗号化の例です","body": "これは暗号化された本文です", "sound": "typewriter"})

# KEY 長さ: AES128-16 | AES192-24 | AES256-32
key = b"LikXhHgcmHjxoayK3kfzSWP4qp8zPhf1"
# IV(Nonce) はランダム生成可能。ランダムの場合は先頭に付与して一緒に送る必要があります。
nonce = os.urandom(12)

# 暗号化
cipher = AES.new(key, AES.MODE_GCM, nonce)
padded_data = json_example.encode()
encrypted_data, tag = cipher.encrypt_and_digest(padded_data)
encrypted_data =  nonce + encrypted_data + tag

# 暗号化したデータを Base64 エンコード
encrypted_base64 = base64.b64encode(encrypted_data).decode()

print("暗号化されたデータ（Base64）", encrypted_base64)


res = requests.get("https://dev.uuneo.com/StoUxq6ed2h9RRszEMBkpn/test", params = {"ciphertext": encrypted_base64, "cipherNumber":0})

print(res.text)

```

**JavaScript 例:**

```javascript
import crypto from "crypto";
import https from "https";

// 1. JSON データの用意
const jsonExample = JSON.stringify({
  title: "これは暗号化の例です",
  body: "これは暗号化された本文です",
  sound: "typewriter",
});

// 2. AES キー（長さでアルゴリズムが決定: 16=128bit, 24=192bit, 32=256bit）
const key = Buffer.from("e6E7vVgsjDysdNt8HsmXsuAvD9VTzjEG", "utf8");

// 3. ランダム 12 バイトの nonce（IV）
const nonce = crypto.randomBytes(12);

// 4. AES-GCM cipher の作成
const cipher = crypto.createCipheriv("aes-256-gcm", key, nonce);

// 5. データの暗号化
let encrypted = cipher.update(jsonExample, "utf8");
encrypted = Buffer.concat([encrypted, cipher.final()]);

// 6. 認証タグ tag を取得
const tag = cipher.getAuthTag();

// 7. nonce + ciphertext + tag を結合
const encryptedData = Buffer.concat([nonce, encrypted, tag]);

// 8. Base64 へ変換
const encryptedBase64 = encryptedData.toString("base64");

console.log("暗号化されたデータ（Base64）:", encryptedBase64);

// 9. サーバーへリクエスト送信
const url = new URL("https://dev.uuneo.com/UPJJV8AkkHgbDKYwXDfjZN/test");
url.searchParams.append("ciphertext", encryptedBase64);
url.searchParams.append("cipherNumber", 0);

https.get(url, (res) => {
  let data = "";
  res.on("data", (chunk) => (data += chunk));
  res.on("end", () => console.log("サーバー応答:", data));
});

```

**Golang 例:**

```golang
package main

import (
    "crypto/aes"
    "crypto/cipher"
    "crypto/rand"
    "encoding/base64"
    "encoding/json"
    "fmt"
    "io"
    "net/http"
    "net/url"
)

func main() {
    // 1. JSON データを構築
    jsonExample := map[string]string{
        "title": "これは暗号化の例です",
        "body":  "これは暗号化された本文です",
        "sound": "typewriter",
    }
    jsonData, _ := json.Marshal(jsonExample)

    // 2. AES キー（16 = AES-128, 24 = AES-192, 32 = AES-256）
    key := []byte("e6E7vVgsjDysdNt8HsmXsuAvD9VTzjEG") // 32 バイト → AES-256

    // 3. ランダム 12 バイトの nonce (IV) を生成
    nonce := make([]byte, 12)
    if _, err := io.ReadFull(rand.Reader, nonce); err != nil {
        panic(err)
    }

    // 4. AES-GCM 暗号器の作成
    block, err := aes.NewCipher(key)
    if err != nil {
        panic(err)
    }
    aesgcm, err := cipher.NewGCM(block)
    if err != nil {
        panic(err)
    }

    // 5. データを暗号化
    ciphertext := aesgcm.Seal(nil, nonce, jsonData, nil)

    // 6. nonce + ciphertext を結合（ciphertext の末尾に tag が含まれます）
    encryptedData := append(nonce, ciphertext...)

    // 7. Base64 エンコード
    encryptedBase64 := base64.StdEncoding.EncodeToString(encryptedData)
    fmt.Println("暗号化されたデータ（Base64）:", encryptedBase64)

    // ローカル復号検証（任意）：ローカルの暗号化/復号が正しいか確認
    {
        decoded, err := base64.StdEncoding.DecodeString(encryptedBase64)
        if err != nil {
            fmt.Println("base64 デコードエラー:", err)
        } else if len(decoded) < 12 {
            fmt.Println("デコードされたデータが短すぎます")
        } else {
            n := decoded[:12]
            ct := decoded[12:]
            plain, err := aesgcm.Open(nil, n, ct, nil)
            if err != nil {
                fmt.Println("ローカル復号に失敗:", err)
            } else {
                fmt.Println("ローカル復号に成功、平文:", string(plain))
            }
        }
    }

    // 8. url.Values を使って URL エンコード（Python requests.params と同等）
    baseURL := "https://dev.uuneo.com/UPJJV8AkkHgbDKYwXDfjZN/test"
    values := url.Values{}
    values.Set("ciphertext", encryptedBase64)
    values.Set("cipherNumber", "0")

    reqURL := baseURL + "?" + values.Encode()
    fmt.Println("リクエスト URL（エンコード済み）:", reqURL)

    // 9. リクエスト送信
    resp, err := http.Get(reqURL)
    if err != nil {
        panic(err)
    }
    defer resp.Body.Close()

    body, _ := io.ReadAll(resp.Body)
    fmt.Println("サーバー応答ステータス:", resp.Status)
    fmt.Println("サーバー応答本文:", string(body))
}

```

**PHP 例:**

```php
<?php

// 1. JSON データ
$data = [
    "title" => "これは暗号化の例です",
    "body"  => "これは暗号化された本文です",
    "sound" => "typewriter"
];
$jsonData = json_encode($data);

// 2. AES キー（長さ 32 バイト → AES-256）
$key = "e6E7vVgsjDysdNt8HsmXsuAvD9VTzjEG"; // 32 bytes

// 3. ランダム 12 バイトの nonce (IV) を生成
$nonce = random_bytes(12); // PHP 7+

// 4. データを暗号化（AES-256-GCM）
$cipher = "aes-256-gcm";
$tag = ""; // GCM tag
$ciphertext = openssl_encrypt(
    $jsonData,
    $cipher,
    $key,
    OPENSSL_RAW_DATA,
    $nonce,
    $tag,
    "", // 追加認証データ（AAD、空でも可）
    16  // tag 長さ 16 バイト
);

// 5. nonce + ciphertext + tag を結合
$encryptedData = $nonce . $ciphertext . $tag;

// 6. Base64 エンコード
$encryptedBase64 = base64_encode($encryptedData);

echo "暗号化されたデータ（Base64）: " . $encryptedBase64 . "\n";

// 7. HTTP GET リクエスト送信（URL エンコード）
$baseURL = "https://dev.uuneo.com/UPJJV8AkkHgbDKYwXDfjZN/test";
$params = http_build_query([
    "ciphertext" => $encryptedBase64,
    "cipherNumber" => 0
]);
$url = $baseURL . "?" . $params;

$response = file_get_contents($url);
echo "サーバー応答: " . $response . "\n";

// 8. ローカル復号検証（任意）
$decoded = base64_decode($encryptedBase64);
$n = substr($decoded, 0, 12);
$c = substr($decoded, 12, strlen($decoded)-12-16);
$t = substr($decoded, -16);

$decrypted = openssl_decrypt($c, $cipher, $key, OPENSSL_RAW_DATA, $n, $t);
echo "ローカル復号検証の平文: " . $decrypted . "\n";

```

**Java 例:**

```Java
import javax.crypto.Cipher;
import javax.crypto.spec.GCMParameterSpec;
import javax.crypto.spec.SecretKeySpec;
import java.net.URLEncoder;
import java.net.URL;
import java.net.HttpURLConnection;
import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.security.SecureRandom;
import java.util.Base64;

public class AESGCMEncryptSend {

    public static void main(String[] args) throws Exception {
        // -------------------- 1. JSON データ --------------------
        String jsonData = "{\"title\":\"これは暗号化の例です\",\"body\":\"これは暗号化された本文です\",\"sound\":\"typewriter\"}";

        // -------------------- 2. AES キー (32 バイト → AES-256) --------------------
        byte[] keyBytes = "e6E7vVgsjDysdNt8HsmXsuAvD9VTzjEG".getBytes("UTF-8");
        SecretKeySpec key = new SecretKeySpec(keyBytes, "AES");

        // -------------------- 3. ランダム 12 バイトの nonce --------------------
        byte[] nonce = new byte[12];
        SecureRandom random = new SecureRandom();
        random.nextBytes(nonce);

        // -------------------- 4. AES-GCM 暗号化 --------------------
        Cipher cipher = Cipher.getInstance("AES/GCM/NoPadding");
        GCMParameterSpec spec = new GCMParameterSpec(16 * 8, nonce); // tag 16 バイト
        cipher.init(Cipher.ENCRYPT_MODE, key, spec);

        byte[] ciphertext = cipher.doFinal(jsonData.getBytes("UTF-8"));

        // -------------------- 5. nonce + ciphertext を結合 --------------------
        byte[] encryptedData = new byte[nonce.length + ciphertext.length];
        System.arraycopy(nonce, 0, encryptedData, 0, nonce.length);
        System.arraycopy(ciphertext, 0, encryptedData, nonce.length, ciphertext.length);

        // -------------------- 6. Base64 エンコード --------------------
        String encryptedBase64 = Base64.getEncoder().encodeToString(encryptedData);
        System.out.println("暗号化されたデータ(Base64): " + encryptedBase64);

        // -------------------- 7. HTTP GET リクエストを送信 --------------------
        String baseURL = "https://dev.uuneo.com/UPJJV8AkkHgbDKYwXDfjZN/test";
        String urlStr = baseURL
                + "?ciphertext=" + URLEncoder.encode(encryptedBase64, "UTF-8")
                + "&cipherNumber=0";

        URL url = new URL(urlStr);
        HttpURLConnection conn = (HttpURLConnection) url.openConnection();
        conn.setRequestMethod("GET");

        BufferedReader in = new BufferedReader(new InputStreamReader(conn.getInputStream()));
        String line;
        StringBuilder response = new StringBuilder();
        while ((line = in.readLine()) != null) {
            response.append(line);
        }
        in.close();

        System.out.println("サーバー応答: " + response.toString());
    }
}

```

**C 例:**

```C
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <openssl/evp.h>
#include <openssl/rand.h>
#include <openssl/bio.h>
#include <openssl/buffer.h>
#include <curl/curl.h>

// Base64 エンコード
char* base64_encode(const unsigned char* buffer, size_t length) {
    BIO *bio, *b64;
    BUF_MEM *bufferPtr;
    b64 = BIO_new(BIO_f_base64());
    bio = BIO_new(BIO_s_mem());
    bio = BIO_push(b64, bio);
    BIO_set_flags(bio, BIO_FLAGS_BASE64_NO_NL);
    BIO_write(bio, buffer, length);
    BIO_flush(bio);
    BIO_get_mem_ptr(bio, &bufferPtr);
    char* b64text = (char*)malloc(bufferPtr->length + 1);
    memcpy(b64text, bufferPtr->data, bufferPtr->length);
    b64text[bufferPtr->length] = '\0';
    BIO_free_all(bio);
    return b64text;
}

int main() {
    // JSON データ
    const char* jsonData = "{\"title\":\"これは暗号化の例です\",\"body\":\"これは暗号化された本文です\",\"sound\":\"typewriter\"}";
    int jsonLen = strlen(jsonData);

    // AES-256 キー
    unsigned char key[32] = "e6E7vVgsjDysdNt8HsmXsuAvD9VTzjEG";

    // ランダム 12 バイトの nonce
    unsigned char nonce[12];
    if (!RAND_bytes(nonce, sizeof(nonce))) { printf("nonce の生成に失敗\n"); return 1; }

    // AES-GCM 暗号化
    unsigned char ciphertext[1024];
    unsigned char tag[16];
    int len, ciphertext_len;

    EVP_CIPHER_CTX *ctx = EVP_CIPHER_CTX_new();
    EVP_EncryptInit_ex(ctx, EVP_aes_256_gcm(), NULL, NULL, NULL);
    EVP_EncryptInit_ex(ctx, NULL, NULL, key, nonce);
    EVP_EncryptUpdate(ctx, ciphertext, &len, (unsigned char*)jsonData, jsonLen);
    ciphertext_len = len;
    EVP_EncryptFinal_ex(ctx, ciphertext + len, &len);
    ciphertext_len += len;
    EVP_CIPHER_CTX_ctrl(ctx, EVP_CTRL_GCM_GET_TAG, 16, tag);
    EVP_CIPHER_CTX_free(ctx);

    // nonce + ciphertext + tag を結合
    unsigned char encryptedData[1024];
    memcpy(encryptedData, nonce, sizeof(nonce));
    memcpy(encryptedData + sizeof(nonce), ciphertext, ciphertext_len);
    memcpy(encryptedData + sizeof(nonce) + ciphertext_len, tag, sizeof(tag));
    int total_len = sizeof(nonce) + ciphertext_len + sizeof(tag);

    // Base64
    char* encryptedBase64 = base64_encode(encryptedData, total_len);
    printf("暗号化されたデータ(Base64): %s\n", encryptedBase64);

    // ------------------- HTTP GET 送信 -------------------
    CURL *curl = curl_easy_init();
    if(curl) {
        char url[4096];

        // URL エンコード（Base64 の暗号文）
        char* encoded = curl_easy_escape(curl, encryptedBase64, 0);

        snprintf(url, sizeof(url),
                "https://dev.uuneo.com/UPJJV8AkkHgbDKYwXDfjZN/test?ciphertext=%s&cipherNumber=0",
                encoded);

        curl_easy_setopt(curl, CURLOPT_URL, url);
        curl_easy_setopt(curl, CURLOPT_FOLLOWLOCATION, 1L);
        curl_easy_perform(curl);

        curl_free(encoded);
        curl_easy_cleanup(curl);
    }


    free(encryptedBase64);
    return 0;
}

```