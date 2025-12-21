# 推送加密

推送加密是一种保护推送内容的方法，它使用自定义秘钥在发送和接收时对推送内容进行加密和解密。<br>这样，推送内容在传输过程中就不会被 NoLet 服务器和苹果 APNs 服务器获取或泄露。

#### 设置自定义秘钥

1. 打开APP首页
2. 找到 “推送加密” ，点击加密设置
3. 选择加密算法，按要求填写KEY，点击完成保存自定义秘钥, cipherNumber是列表顺序,默认值0
4. 加密模式`markdown`和`body`字段不能简写或者别名(`md`, `text`, `content`, `data`, `message` 都是非法的)*

#### 发送加密推送

要发送加密推送，首先需要把 NoLet 请求参数转换成 json 格式的字符串，然后用之前设置的秘钥和相应的算法对字符串进行加密，最后把加密后的密文作为ciphertext参数发送到服务器。<br><br>

以下是各种语言示例

**Python 示例：**

```python
# Documentation: https://wiki.wzs.app/#/encryption
# python demo: 使用AES加密数据，并发送到服务器
# pip3 install pycryptodome

import os
import json
import base64
import requests
from Crypto.Cipher import AES


# JSON数据
json_example = json.dumps({"title": "这是一个加密示例","body": "这是加密的正文部分", "sound": "typewriter"})

# KEY长度: AES128-16 | AES192-24 | AES256-32
key = b"LikXhHgcmHjxoayK3kfzSWP4qp8zPhf1"
# IV可以是随机生成的，但如果是随机的就需要放在 iv 参数里传递。
nonce = os.urandom(12)

# 加密
cipher = AES.new(key, AES.MODE_GCM, nonce)
padded_data = json_example.encode()
encrypted_data, tag = cipher.encrypt_and_digest(padded_data)
encrypted_data =  nonce + encrypted_data + tag

# 将加密后的数据转换为Base64编码
encrypted_base64 = base64.b64encode(encrypted_data).decode()

print("加密后的数据（Base64编码", encrypted_base64)


res = requests.get("https://wzs.app/StoUxq6ed2h9RRszEMBkpn/test", params = {"ciphertext": encrypted_base64, "cipherNumber":0})

print(res.text)

```
**Javascript 示例：**

```javascript

import crypto from "crypto";
import https from "https";

// 1. 准备 JSON 数据
const jsonExample = JSON.stringify({
  title: "这是一个加密示例",
  body: "这是加密的正文部分",
  sound: "typewriter",
});

// 2. AES 密钥（长度决定算法：16=128bit, 24=192bit, 32=256bit）
const key = Buffer.from("e6E7vVgsjDysdNt8HsmXsuAvD9VTzjEG", "utf8");

// 3. 随机 12 字节 nonce（IV）
const nonce = crypto.randomBytes(12);

// 4. 创建 AES-GCM cipher
const cipher = crypto.createCipheriv("aes-256-gcm", key, nonce);

// 5. 加密数据
let encrypted = cipher.update(jsonExample, "utf8");
encrypted = Buffer.concat([encrypted, cipher.final()]);

// 6. 获取认证标签 tag
const tag = cipher.getAuthTag();

// 7. 拼接 nonce + ciphertext + tag
const encryptedData = Buffer.concat([nonce, encrypted, tag]);

// 8. 转 Base64
const encryptedBase64 = encryptedData.toString("base64");

console.log("加密后的数据（Base64编码）:", encryptedBase64);

// 9. 发送请求到服务器
const url = new URL("https://wzs.app/UPJJV8AkkHgbDKYwXDfjZN/test");
url.searchParams.append("ciphertext", encryptedBase64);
url.searchParams.append("cipherNumber", 0);

https.get(url, (res) => {
  let data = "";
  res.on("data", (chunk) => (data += chunk));
  res.on("end", () => console.log("服务器响应:", data));
});


```
**Golang 示例：**

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
	// 1. 构造 JSON 数据
	jsonExample := map[string]string{
		"title": "这是一个加密示例",
		"body":  "这是加密的正文部分",
		"sound": "typewriter",
	}
	jsonData, _ := json.Marshal(jsonExample)

	// 2. AES 密钥（16 = AES-128, 24 = AES-192, 32 = AES-256）
	key := []byte("e6E7vVgsjDysdNt8HsmXsuAvD9VTzjEG") // 32 字节 → AES-256

	// 3. 生成随机 12 字节 nonce (IV)
	nonce := make([]byte, 12)
	if _, err := io.ReadFull(rand.Reader, nonce); err != nil {
		panic(err)
	}

	// 4. 创建 AES-GCM 加密器
	block, err := aes.NewCipher(key)
	if err != nil {
		panic(err)
	}
	aesgcm, err := cipher.NewGCM(block)
	if err != nil {
		panic(err)
	}

	// 5. 加密数据
	ciphertext := aesgcm.Seal(nil, nonce, jsonData, nil)

	// 6. 拼接 nonce + ciphertext (ciphertext already contains tag at end)
	encryptedData := append(nonce, ciphertext...)

	// 7. Base64 编码
	encryptedBase64 := base64.StdEncoding.EncodeToString(encryptedData)
	fmt.Println("加密后的数据（Base64）:", encryptedBase64)

	// 本地解密验证（可用于确认本地加密/解密正确）
	{
		decoded, err := base64.StdEncoding.DecodeString(encryptedBase64)
		if err != nil {
			fmt.Println("base64 decode error:", err)
		} else if len(decoded) < 12 {
			fmt.Println("decoded data too short")
		} else {
			n := decoded[:12]
			ct := decoded[12:]
			plain, err := aesgcm.Open(nil, n, ct, nil)
			if err != nil {
				fmt.Println("local decrypt failed:", err)
			} else {
				fmt.Println("本地解密成功，明文:", string(plain))
			}
		}
	}

	// 8. 使用 url.Values 自动做 URL 编码（等同于 Python requests.params）
	baseURL := "https://wzs.app/UPJJV8AkkHgbDKYwXDfjZN/test"
	values := url.Values{}
	values.Set("ciphertext", encryptedBase64)
	values.Set("cipherNumber", "0")

	reqURL := baseURL + "?" + values.Encode()
	fmt.Println("请求 URL (已编码):", reqURL)

	// 9. 发起请求
	resp, err := http.Get(reqURL)
	if err != nil {
		panic(err)
	}
	defer resp.Body.Close()

	body, _ := io.ReadAll(resp.Body)
	fmt.Println("服务器响应状态:", resp.Status)
	fmt.Println("服务器响应体:", string(body))
}


```

**PHP 示例：**

```php

<?php

// 1. JSON 数据
$data = [
    "title" => "这是一个加密示例",
    "body"  => "这是加密的正文部分",
    "sound" => "typewriter"
];
$jsonData = json_encode($data);

// 2. AES 密钥（长度 32 字节 → AES-256）
$key = "e6E7vVgsjDysdNt8HsmXsuAvD9VTzjEG"; // 32 bytes

// 3. 生成随机 12 字节 nonce (IV)
$nonce = random_bytes(12); // PHP 7+

// 4. 加密数据（AES-256-GCM）
$cipher = "aes-256-gcm";
$tag = ""; // GCM tag
$ciphertext = openssl_encrypt(
    $jsonData,
    $cipher,
    $key,
    OPENSSL_RAW_DATA,
    $nonce,
    $tag,
    "", // 额外认证数据（AAD，可为空）
    16  // tag 长度 16 字节
);

// 5. 拼接 nonce + ciphertext + tag
$encryptedData = $nonce . $ciphertext . $tag;

// 6. Base64 编码
$encryptedBase64 = base64_encode($encryptedData);

echo "加密后的数据（Base64编码）: " . $encryptedBase64 . "\n";

// 7. 发送 HTTP GET 请求（URL 编码）
$baseURL = "https://wzs.app/UPJJV8AkkHgbDKYwXDfjZN/test";
$params = http_build_query([
    "ciphertext" => $encryptedBase64,
    "cipherNumber" => 0
]);
$url = $baseURL . "?" . $params;

$response = file_get_contents($url);
echo "服务器响应: " . $response . "\n";

// 8. 本地解密验证（可选）
$decoded = base64_decode($encryptedBase64);
$n = substr($decoded, 0, 12);
$c = substr($decoded, 12, strlen($decoded)-12-16);
$t = substr($decoded, -16);

$decrypted = openssl_decrypt($c, $cipher, $key, OPENSSL_RAW_DATA, $n, $t);
echo "本地解密验证明文: " . $decrypted . "\n";


```


**Java 示例：**

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
        // -------------------- 1. JSON 数据 --------------------
        String jsonData = "{\"title\":\"这是一个加密示例\",\"body\":\"这是加密的正文部分\",\"sound\":\"typewriter\"}";

        // -------------------- 2. AES 密钥 (32字节 → AES-256) --------------------
        byte[] keyBytes = "e6E7vVgsjDysdNt8HsmXsuAvD9VTzjEG".getBytes("UTF-8");
        SecretKeySpec key = new SecretKeySpec(keyBytes, "AES");

        // -------------------- 3. 随机 12 字节 nonce --------------------
        byte[] nonce = new byte[12];
        SecureRandom random = new SecureRandom();
        random.nextBytes(nonce);

        // -------------------- 4. AES-GCM 加密 --------------------
        Cipher cipher = Cipher.getInstance("AES/GCM/NoPadding");
        GCMParameterSpec spec = new GCMParameterSpec(16 * 8, nonce); // 16 bytes tag
        cipher.init(Cipher.ENCRYPT_MODE, key, spec);

        byte[] ciphertext = cipher.doFinal(jsonData.getBytes("UTF-8"));

        // -------------------- 5. 拼接 nonce + ciphertext --------------------
        byte[] encryptedData = new byte[nonce.length + ciphertext.length];
        System.arraycopy(nonce, 0, encryptedData, 0, nonce.length);
        System.arraycopy(ciphertext, 0, encryptedData, nonce.length, ciphertext.length);

        // -------------------- 6. Base64 编码 --------------------
        String encryptedBase64 = Base64.getEncoder().encodeToString(encryptedData);
        System.out.println("加密后的数据(Base64): " + encryptedBase64);

        // -------------------- 7. 发送 HTTP GET 请求 --------------------
        String baseURL = "https://wzs.app/UPJJV8AkkHgbDKYwXDfjZN/test";
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

        System.out.println("服务器响应: " + response.toString());
    }
}



```

**C 示例：**

```C
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <openssl/evp.h>
#include <openssl/rand.h>
#include <openssl/bio.h>
#include <openssl/buffer.h>
#include <curl/curl.h>

// Base64 编码
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
    // JSON 数据
    const char* jsonData = "{\"title\":\"这是一个加密示例\",\"body\":\"这是加密的正文部分\",\"sound\":\"typewriter\"}";
    int jsonLen = strlen(jsonData);

    // AES-256 key
    unsigned char key[32] = "e6E7vVgsjDysdNt8HsmXsuAvD9VTzjEG";

    // 随机 12 字节 nonce
    unsigned char nonce[12];
    if (!RAND_bytes(nonce, sizeof(nonce))) { printf("生成nonce失败\n"); return 1; }

    // AES-GCM 加密
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

    // 拼接 nonce + ciphertext + tag
    unsigned char encryptedData[1024];
    memcpy(encryptedData, nonce, sizeof(nonce));
    memcpy(encryptedData + sizeof(nonce), ciphertext, ciphertext_len);
    memcpy(encryptedData + sizeof(nonce) + ciphertext_len, tag, sizeof(tag));
    int total_len = sizeof(nonce) + ciphertext_len + sizeof(tag);

    // Base64
    char* encryptedBase64 = base64_encode(encryptedData, total_len);
    printf("加密后的数据(Base64): %s\n", encryptedBase64);

    // ------------------- 发送 HTTP GET -------------------
    CURL *curl = curl_easy_init();
    if(curl) {
        char url[4096];

        // URL 编码 Base64 密文
        char* encoded = curl_easy_escape(curl, encryptedBase64, 0);

        snprintf(url, sizeof(url),
                "https://wzs.app/UPJJV8AkkHgbDKYwXDfjZN/test?ciphertext=%s&cipherNumber=0",
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