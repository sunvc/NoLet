# What is Push Encryption

Push encryption is a method to protect notification content. It uses a custom key to encrypt and decrypt data when sending and receiving.<br>This way, the content cannot be accessed or leaked by the NoLet server or Apple APNs during transmission.

#### Set a Custom Key
1. Open the app home screen
2. Find “Push Encryption” and open the encryption settings
3. Choose an encryption algorithm, fill in the KEY as required, and tap Done to save your custom key. `cipherNumber` is the list order (index), default is `0`.

#### Send an Encrypted Push
To send an encrypted push, first convert NoLet request parameters into a JSON string. Then encrypt the string with the previously set key and chosen algorithm. Finally, concatenate the data as `nonce + ciphertext [+ tag]`, encode it in Base64, and send the result in the `ciphertext` parameter to the server.<br><br>

Below are examples in various languages.

**Python Example:**

```python
# Documentation: https://wiki.wzs.app/#/encryption
# Python demo: Encrypt data with AES and send to the server
# pip3 install pycryptodome

import os
import json
import base64
import requests
from Crypto.Cipher import AES


# JSON data
json_example = json.dumps({"title": "This is an encryption example","body": "This is the encrypted body", "sound": "typewriter"})

# KEY length: AES128-16 | AES192-24 | AES256-32
key = b"LikXhHgcmHjxoayK3kfzSWP4qp8zPhf1"
# IV (nonce) can be randomly generated. If random, prepend it so the receiver has it.
nonce = os.urandom(12)

# Encrypt
cipher = AES.new(key, AES.MODE_GCM, nonce)
padded_data = json_example.encode()
encrypted_data, tag = cipher.encrypt_and_digest(padded_data)
encrypted_data =  nonce + encrypted_data + tag

# Convert encrypted data to Base64
encrypted_base64 = base64.b64encode(encrypted_data).decode()

print("Encrypted data (Base64)", encrypted_base64)


res = requests.get("https://wzs.app/StoUxq6ed2h9RRszEMBkpn/test", params = {"ciphertext": encrypted_base64, "cipherNumber":0})

print(res.text)

```

**JavaScript Example:**

```javascript
import crypto from "crypto";
import https from "https";

// 1. Prepare JSON data
const jsonExample = JSON.stringify({
  title: "This is an encryption example",
  body: "This is the encrypted body",
  sound: "typewriter",
});

// 2. AES key (length decides algorithm: 16=128bit, 24=192bit, 32=256bit)
const key = Buffer.from("e6E7vVgsjDysdNt8HsmXsuAvD9VTzjEG", "utf8");

// 3. Random 12-byte nonce (IV)
const nonce = crypto.randomBytes(12);

// 4. Create AES-GCM cipher
const cipher = crypto.createCipheriv("aes-256-gcm", key, nonce);

// 5. Encrypt data
let encrypted = cipher.update(jsonExample, "utf8");
encrypted = Buffer.concat([encrypted, cipher.final()]);

// 6. Get auth tag
const tag = cipher.getAuthTag();

// 7. Concatenate nonce + ciphertext + tag
const encryptedData = Buffer.concat([nonce, encrypted, tag]);

// 8. To Base64
const encryptedBase64 = encryptedData.toString("base64");

console.log("Encrypted data (Base64):", encryptedBase64);

// 9. Send request to server
const url = new URL("https://wzs.app/UPJJV8AkkHgbDKYwXDfjZN/test");
url.searchParams.append("ciphertext", encryptedBase64);
url.searchParams.append("cipherNumber", 0);

https.get(url, (res) => {
  let data = "";
  res.on("data", (chunk) => (data += chunk));
  res.on("end", () => console.log("Server response:", data));
});

```

**Golang Example:**

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
    // 1. Build JSON data
    jsonExample := map[string]string{
        "title": "This is an encryption example",
        "body":  "This is the encrypted body",
        "sound": "typewriter",
    }
    jsonData, _ := json.Marshal(jsonExample)

    // 2. AES key (16 = AES-128, 24 = AES-192, 32 = AES-256)
    key := []byte("e6E7vVgsjDysdNt8HsmXsuAvD9VTzjEG") // 32 bytes → AES-256

    // 3. Generate random 12-byte nonce (IV)
    nonce := make([]byte, 12)
    if _, err := io.ReadFull(rand.Reader, nonce); err != nil {
        panic(err)
    }

    // 4. Create AES-GCM encrypter
    block, err := aes.NewCipher(key)
    if err != nil {
        panic(err)
    }
    aesgcm, err := cipher.NewGCM(block)
    if err != nil {
        panic(err)
    }

    // 5. Encrypt data
    ciphertext := aesgcm.Seal(nil, nonce, jsonData, nil)

    // 6. Concatenate nonce + ciphertext (GCM result already has tag at end)
    encryptedData := append(nonce, ciphertext...)

    // 7. Base64 encode
    encryptedBase64 := base64.StdEncoding.EncodeToString(encryptedData)
    fmt.Println("Encrypted data (Base64):", encryptedBase64)

    // Local decrypt verification (optional): confirm local encrypt/decrypt is correct
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
                fmt.Println("local decrypt success, plaintext:", string(plain))
            }
        }
    }

    // 8. Use url.Values for URL encoding (same as Python requests.params)
    baseURL := "https://wzs.app/UPJJV8AkkHgbDKYwXDfjZN/test"
    values := url.Values{}
    values.Set("ciphertext", encryptedBase64)
    values.Set("cipherNumber", "0")

    reqURL := baseURL + "?" + values.Encode()
    fmt.Println("Request URL (encoded):", reqURL)

    // 9. Send request
    resp, err := http.Get(reqURL)
    if err != nil {
        panic(err)
    }
    defer resp.Body.Close()

    body, _ := io.ReadAll(resp.Body)
    fmt.Println("Server response status:", resp.Status)
    fmt.Println("Server response body:", string(body))
}

```

**PHP Example:**

```php
<?php

// 1. JSON data
$data = [
    "title" => "This is an encryption example",
    "body"  => "This is the encrypted body",
    "sound" => "typewriter"
];
$jsonData = json_encode($data);

// 2. AES key (length 32 bytes → AES-256)
$key = "e6E7vVgsjDysdNt8HsmXsuAvD9VTzjEG"; // 32 bytes

// 3. Generate random 12-byte nonce (IV)
$nonce = random_bytes(12); // PHP 7+

// 4. Encrypt data (AES-256-GCM)
$cipher = "aes-256-gcm";
$tag = ""; // GCM tag
$ciphertext = openssl_encrypt(
    $jsonData,
    $cipher,
    $key,
    OPENSSL_RAW_DATA,
    $nonce,
    $tag,
    "", // Additional Authenticated Data (AAD), can be empty
    16  // tag length 16 bytes
);

// 5. Concatenate nonce + ciphertext + tag
$encryptedData = $nonce . $ciphertext . $tag;

// 6. Base64 encode
$encryptedBase64 = base64_encode($encryptedData);

echo "Encrypted data (Base64): " . $encryptedBase64 . "\n";

// 7. Send HTTP GET (URL encoded)
$baseURL = "https://wzs.app/UPJJV8AkkHgbDKYwXDfjZN/test";
$params = http_build_query([
    "ciphertext" => $encryptedBase64,
    "cipherNumber" => 0
]);
$url = $baseURL . "?" . $params;

$response = file_get_contents($url);
echo "Server response: " . $response . "\n";

// 8. Local decrypt verification (optional)
$decoded = base64_decode($encryptedBase64);
$n = substr($decoded, 0, 12);
$c = substr($decoded, 12, strlen($decoded)-12-16);
$t = substr($decoded, -16);

$decrypted = openssl_decrypt($c, $cipher, $key, OPENSSL_RAW_DATA, $n, $t);
echo "Local decrypt plaintext: " . $decrypted . "\n";

```

**Java Example:**

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
        // -------------------- 1. JSON data --------------------
        String jsonData = "{\"title\":\"This is an encryption example\",\"body\":\"This is the encrypted body\",\"sound\":\"typewriter\"}";

        // -------------------- 2. AES key (32 bytes → AES-256) --------------------
        byte[] keyBytes = "e6E7vVgsjDysdNt8HsmXsuAvD9VTzjEG".getBytes("UTF-8");
        SecretKeySpec key = new SecretKeySpec(keyBytes, "AES");

        // -------------------- 3. Random 12-byte nonce --------------------
        byte[] nonce = new byte[12];
        SecureRandom random = new SecureRandom();
        random.nextBytes(nonce);

        // -------------------- 4. AES-GCM encryption --------------------
        Cipher cipher = Cipher.getInstance("AES/GCM/NoPadding");
        GCMParameterSpec spec = new GCMParameterSpec(16 * 8, nonce); // 16-byte tag
        cipher.init(Cipher.ENCRYPT_MODE, key, spec);

        byte[] ciphertext = cipher.doFinal(jsonData.getBytes("UTF-8"));

        // -------------------- 5. Concatenate nonce + ciphertext --------------------
        byte[] encryptedData = new byte[nonce.length + ciphertext.length];
        System.arraycopy(nonce, 0, encryptedData, 0, nonce.length);
        System.arraycopy(ciphertext, 0, encryptedData, nonce.length, ciphertext.length);

        // -------------------- 6. Base64 encoding --------------------
        String encryptedBase64 = Base64.getEncoder().encodeToString(encryptedData);
        System.out.println("Encrypted data (Base64): " + encryptedBase64);

        // -------------------- 7. Send HTTP GET request --------------------
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

        System.out.println("Server response: " + response.toString());
    }
}

```

**C Example:**

```C
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <openssl/evp.h>
#include <openssl/rand.h>
#include <openssl/bio.h>
#include <openssl/buffer.h>
#include <curl/curl.h>

// Base64 encoding
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
    // JSON data
    const char* jsonData = "{\"title\":\"This is an encryption example\",\"body\":\"This is the encrypted body\",\"sound\":\"typewriter\"}";
    int jsonLen = strlen(jsonData);

    // AES-256 key
    unsigned char key[32] = "e6E7vVgsjDysdNt8HsmXsuAvD9VTzjEG";

    // Random 12-byte nonce
    unsigned char nonce[12];
    if (!RAND_bytes(nonce, sizeof(nonce))) { printf("Failed to generate nonce\n"); return 1; }

    // AES-GCM encryption
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

    // Concatenate nonce + ciphertext + tag
    unsigned char encryptedData[1024];
    memcpy(encryptedData, nonce, sizeof(nonce));
    memcpy(encryptedData + sizeof(nonce), ciphertext, ciphertext_len);
    memcpy(encryptedData + sizeof(nonce) + ciphertext_len, tag, sizeof(tag));
    int total_len = sizeof(nonce) + ciphertext_len + sizeof(tag);

    // Base64
    char* encryptedBase64 = base64_encode(encryptedData, total_len);
    printf("Encrypted data (Base64): %s\n", encryptedBase64);

    // ------------------- Send HTTP GET -------------------
    CURL *curl = curl_easy_init();
    if(curl) {
        char url[4096];

        // URL-encode the Base64 ciphertext
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