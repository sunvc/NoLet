*오픈소스 프로젝트 [BARK](https://github.com/Finb/Bark)에 감사드립니다*

#### 푸시 암호화란?

푸시 암호화는 푸시(알림) 내용을 보호하기 위한 방법으로, 사용자가 지정한 비밀키를 사용해 전송과 수신 시에 내용을 암호화/복호화합니다.<br>이렇게 하면 전송 과정에서 NoLet 서버나 Apple APNs 서버가 내용을 열람하거나 유출할 수 없습니다.

#### 사용자 지정 키 설정
1. 앱 홈 화면을 엽니다
2. "푸시 암호화" 항목을 찾아 암호화 설정을 엽니다
3. 암호화 알고리즘을 선택하고 요구사항에 맞게 KEY를 입력한 뒤 완료를 눌러 저장합니다. `cipherNumber`는 목록 순서(인덱스)이며 기본값은 `0`입니다.

#### 암호화된 푸시 보내기
암호화된 푸시를 보내려면, 먼저 NoLet 요청 파라미터를 JSON 형식 문자열로 만든 뒤, 앞서 설정한 키와 선택한 알고리즘으로 문자열을 암호화합니다. 마지막으로 암호화 결과를 `nonce + ciphertext [+ tag]` 형태로 이어 붙여 Base64로 인코딩하고, 이를 `ciphertext` 파라미터로 서버에 전송합니다.<br><br>

아래는 다양한 언어별 예시입니다.

**Python 예시:**

```python
# 문서: https://wiki.wzs.app/#/encryption
# Python 데모: AES로 데이터를 암호화하여 서버로 전송
# pip3 install pycryptodome

import os
import json
import base64
import requests
from Crypto.Cipher import AES


# JSON 데이터
json_example = json.dumps({"title": "암호화 예시입니다","body": "암호화된 본문입니다", "sound": "typewriter"})

# KEY 길이: AES128-16 | AES192-24 | AES256-32
key = b"LikXhHgcmHjxoayK3kfzSWP4qp8zPhf1"
# IV(Nonce)는 랜덤 생성 가능. 랜덤인 경우 iv(또는 nonce)를 앞에 붙여 함께 전달해야 합니다.
nonce = os.urandom(12)

# 암호화
cipher = AES.new(key, AES.MODE_GCM, nonce)
padded_data = json_example.encode()
encrypted_data, tag = cipher.encrypt_and_digest(padded_data)
encrypted_data =  nonce + encrypted_data + tag

# 암호화된 데이터를 Base64로 인코딩
encrypted_base64 = base64.b64encode(encrypted_data).decode()

print("암호화된 데이터(Base64)", encrypted_base64)


res = requests.get("https://dev.uuneo.com/StoUxq6ed2h9RRszEMBkpn/test", params = {"ciphertext": encrypted_base64, "cipherNumber":0})

print(res.text)

```

**Javascript 예시:**

```javascript
import crypto from "crypto";
import https from "https";

// 1. JSON 데이터 준비
const jsonExample = JSON.stringify({
  title: "암호화 예시입니다",
  body: "암호화된 본문입니다",
  sound: "typewriter",
});

// 2. AES 키 (길이에 따라 알고리즘 결정: 16=128bit, 24=192bit, 32=256bit)
const key = Buffer.from("e6E7vVgsjDysdNt8HsmXsuAvD9VTzjEG", "utf8");

// 3. 랜덤 12바이트 nonce(IV)
const nonce = crypto.randomBytes(12);

// 4. AES-GCM cipher 생성
const cipher = crypto.createCipheriv("aes-256-gcm", key, nonce);

// 5. 데이터 암호화
let encrypted = cipher.update(jsonExample, "utf8");
encrypted = Buffer.concat([encrypted, cipher.final()]);

// 6. 인증 태그(tag) 가져오기
const tag = cipher.getAuthTag();

// 7. nonce + ciphertext + tag 결합
const encryptedData = Buffer.concat([nonce, encrypted, tag]);

// 8. Base64 인코딩
const encryptedBase64 = encryptedData.toString("base64");

console.log("암호화된 데이터(Base64):", encryptedBase64);

// 9. 서버로 요청 전송
const url = new URL("https://dev.uuneo.com/UPJJV8AkkHgbDKYwXDfjZN/test");
url.searchParams.append("ciphertext", encryptedBase64);
url.searchParams.append("cipherNumber", 0);

https.get(url, (res) => {
  let data = "";
  res.on("data", (chunk) => (data += chunk));
  res.on("end", () => console.log("서버 응답:", data));
});

```

**Golang 예시:**

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
    // 1. JSON 데이터 구성
    jsonExample := map[string]string{
        "title": "암호화 예시입니다",
        "body":  "암호화된 본문입니다",
        "sound": "typewriter",
    }
    jsonData, _ := json.Marshal(jsonExample)

    // 2. AES 키 (16 = AES-128, 24 = AES-192, 32 = AES-256)
    key := []byte("e6E7vVgsjDysdNt8HsmXsuAvD9VTzjEG") // 32바이트 → AES-256

    // 3. 랜덤 12바이트 nonce(IV) 생성
    nonce := make([]byte, 12)
    if _, err := io.ReadFull(rand.Reader, nonce); err != nil {
        panic(err)
    }

    // 4. AES-GCM 암호기 생성
    block, err := aes.NewCipher(key)
    if err != nil {
        panic(err)
    }
    aesgcm, err := cipher.NewGCM(block)
    if err != nil {
        panic(err)
    }

    // 5. 데이터 암호화
    ciphertext := aesgcm.Seal(nil, nonce, jsonData, nil)

    // 6. nonce + ciphertext 결합 (GCM 결과에 tag가 끝에 포함됨)
    encryptedData := append(nonce, ciphertext...)

    // 7. Base64 인코딩
    encryptedBase64 := base64.StdEncoding.EncodeToString(encryptedData)
    fmt.Println("암호화된 데이터(Base64):", encryptedBase64)

    // 로컬 복호화 검증(선택): 로컬 암호화/복호화가 올바른지 확인
    {
        decoded, err := base64.StdEncoding.DecodeString(encryptedBase64)
        if err != nil {
            fmt.Println("base64 디코드 오류:", err)
        } else if len(decoded) < 12 {
            fmt.Println("디코드된 데이터가 너무 짧습니다")
        } else {
            n := decoded[:12]
            ct := decoded[12:]
            plain, err := aesgcm.Open(nil, n, ct, nil)
            if err != nil {
                fmt.Println("로컬 복호화 실패:", err)
            } else {
                fmt.Println("로컬 복호화 성공, 평문:", string(plain))
            }
        }
    }

    // 8. url.Values를 사용해 자동 URL 인코딩 (Python requests.params와 동일)
    baseURL := "https://dev.uuneo.com/UPJJV8AkkHgbDKYwXDfjZN/test"
    values := url.Values{}
    values.Set("ciphertext", encryptedBase64)
    values.Set("cipherNumber", "0")

    reqURL := baseURL + "?" + values.Encode()
    fmt.Println("요청 URL(인코딩 완료):", reqURL)

    // 9. 요청 전송
    resp, err := http.Get(reqURL)
    if err != nil {
        panic(err)
    }
    defer resp.Body.Close()

    body, _ := io.ReadAll(resp.Body)
    fmt.Println("서버 응답 상태:", resp.Status)
    fmt.Println("서버 응답 본문:", string(body))
}

```

**PHP 예시:**

```php
<?php

// 1. JSON 데이터
$data = [
    "title" => "암호화 예시입니다",
    "body"  => "암호화된 본문입니다",
    "sound" => "typewriter"
];
$jsonData = json_encode($data);

// 2. AES 키(길이 32바이트 → AES-256)
$key = "e6E7vVgsjDysdNt8HsmXsuAvD9VTzjEG"; // 32 bytes

// 3. 랜덤 12바이트 nonce(IV) 생성
$nonce = random_bytes(12); // PHP 7+

// 4. 데이터 암호화(AES-256-GCM)
$cipher = "aes-256-gcm";
$tag = ""; // GCM tag
$ciphertext = openssl_encrypt(
    $jsonData,
    $cipher,
    $key,
    OPENSSL_RAW_DATA,
    $nonce,
    $tag,
    "", // 추가 인증 데이터(AAD), 비워둘 수 있음
    16  // tag 길이 16바이트
);

// 5. nonce + ciphertext + tag 결합
$encryptedData = $nonce . $ciphertext . $tag;

// 6. Base64 인코딩
$encryptedBase64 = base64_encode($encryptedData);

echo "암호화된 데이터(Base64): " . $encryptedBase64 . "\n";

// 7. HTTP GET 요청 전송(URL 인코딩)
$baseURL = "https://dev.uuneo.com/UPJJV8AkkHgbDKYwXDfjZN/test";
$params = http_build_query([
    "ciphertext" => $encryptedBase64,
    "cipherNumber" => 0
]);
$url = $baseURL . "?" . $params;

$response = file_get_contents($url);
echo "서버 응답: " . $response . "\n";

// 8. 로컬 복호화 검증(선택)
$decoded = base64_decode($encryptedBase64);
$n = substr($decoded, 0, 12);
$c = substr($decoded, 12, strlen($decoded)-12-16);
$t = substr($decoded, -16);

$decrypted = openssl_decrypt($c, $cipher, $key, OPENSSL_RAW_DATA, $n, $t);
echo "로컬 복호화 검증 평문: " . $decrypted . "\n";

```

**Java 예시:**

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
        // -------------------- 1. JSON 데이터 --------------------
        String jsonData = "{\"title\":\"암호화 예시입니다\",\"body\":\"암호화된 본문입니다\",\"sound\":\"typewriter\"}";

        // -------------------- 2. AES 키(32바이트 → AES-256) --------------------
        byte[] keyBytes = "e6E7vVgsjDysdNt8HsmXsuAvD9VTzjEG".getBytes("UTF-8");
        SecretKeySpec key = new SecretKeySpec(keyBytes, "AES");

        // -------------------- 3. 랜덤 12바이트 nonce --------------------
        byte[] nonce = new byte[12];
        SecureRandom random = new SecureRandom();
        random.nextBytes(nonce);

        // -------------------- 4. AES-GCM 암호화 --------------------
        Cipher cipher = Cipher.getInstance("AES/GCM/NoPadding");
        GCMParameterSpec spec = new GCMParameterSpec(16 * 8, nonce); // tag 16바이트
        cipher.init(Cipher.ENCRYPT_MODE, key, spec);

        byte[] ciphertext = cipher.doFinal(jsonData.getBytes("UTF-8"));

        // -------------------- 5. nonce + ciphertext 결합 --------------------
        byte[] encryptedData = new byte[nonce.length + ciphertext.length];
        System.arraycopy(nonce, 0, encryptedData, 0, nonce.length);
        System.arraycopy(ciphertext, 0, encryptedData, nonce.length, ciphertext.length);

        // -------------------- 6. Base64 인코딩 --------------------
        String encryptedBase64 = Base64.getEncoder().encodeToString(encryptedData);
        System.out.println("암호화된 데이터(Base64): " + encryptedBase64);

        // -------------------- 7. HTTP GET 요청 보내기 --------------------
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

        System.out.println("서버 응답: " + response.toString());
    }
}

```

**C 예시:**

```C
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <openssl/evp.h>
#include <openssl/rand.h>
#include <openssl/bio.h>
#include <openssl/buffer.h>
#include <curl/curl.h>

// Base64 인코딩
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
    // JSON 데이터
    const char* jsonData = "{\"title\":\"암호화 예시입니다\",\"body\":\"암호화된 본문입니다\",\"sound\":\"typewriter\"}";
    int jsonLen = strlen(jsonData);

    // AES-256 키
    unsigned char key[32] = "e6E7vVgsjDysdNt8HsmXsuAvD9VTzjEG";

    // 랜덤 12바이트 nonce
    unsigned char nonce[12];
    if (!RAND_bytes(nonce, sizeof(nonce))) { printf("nonce 생성 실패\n"); return 1; }

    // AES-GCM 암호화
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

    // nonce + ciphertext + tag 결합
    unsigned char encryptedData[1024];
    memcpy(encryptedData, nonce, sizeof(nonce));
    memcpy(encryptedData + sizeof(nonce), ciphertext, ciphertext_len);
    memcpy(encryptedData + sizeof(nonce) + ciphertext_len, tag, sizeof(tag));
    int total_len = sizeof(nonce) + ciphertext_len + sizeof(tag);

    // Base64 인코딩
    char* encryptedBase64 = base64_encode(encryptedData, total_len);
    printf("암호화된 데이터(Base64): %s\n", encryptedBase64);

    // ------------------- HTTP GET 전송 -------------------
    CURL *curl = curl_easy_init();
    if(curl) {
        char url[4096];

        // URL 인코딩(Base64 암호문)
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