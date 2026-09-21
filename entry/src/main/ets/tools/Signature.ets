import { cryptoFramework } from '@kit.CryptoArchitectureKit';
import { util } from '@kit.ArkTS';
import { noletUserAgent } from './UserAgent';
import { appStore } from '../store/AppStore';
import { DEFAULT_KEY } from '../model/CryptoConfig';

// 对应 iOS CryptoManager.signature：用 AES-GCM 加密当前秒级时间戳，
// 输出 URL-safe base64（nonce 12 字节 + 密文 + tag 16 字节）。
// 密钥取加密配置列表第一个（对应 iOS config(0)），其长度决定 AES128/192/256。

const NONCE_LEN: number = 12;
const TAG_LEN: number = 16;
const ALNUM: string = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';

function activeKey(): string {
  const list = appStore.getState().cryptoConfigs;
  return list.length > 0 && list[0].key ? list[0].key : DEFAULT_KEY;
}

function randomNonce(): Uint8Array {
  const bytes: Uint8Array = new Uint8Array(NONCE_LEN);
  for (let i = 0; i < NONCE_LEN; i++) {
    bytes[i] = ALNUM.charCodeAt(Math.floor(Math.random() * ALNUM.length));
  }
  return bytes;
}

function urlSafeBase64(bytes: Uint8Array): string {
  return new util.Base64Helper().encodeToStringSync(bytes)
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=/g, '');
}

// 加密时间戳，返回与 iOS safeBase64 一致的 URL-safe base64
async function signTimestamp(timestamp: string, key: string): Promise<string> {
  const alg: string = `AES${key.length * 8}`;
  const keyGenerator = cryptoFramework.createSymKeyGenerator(alg);
  const keyBytes: Uint8Array = new util.TextEncoder().encodeInto(key);
  const symKey = await keyGenerator.convertKey({ data: keyBytes });

  const cipher = cryptoFramework.createCipher(`${alg}|GCM|NoPadding`);
  const nonce: Uint8Array = randomNonce();
  const params: cryptoFramework.GcmParamsSpec = {
    algName: 'GcmParamsSpec',
    iv: { data: nonce },
    aad: { data: new Uint8Array(0) },
    authTag: { data: new Uint8Array(TAG_LEN) },
  };
  await cipher.init(cryptoFramework.CryptoMode.ENCRYPT_MODE, symKey, params);

  const plain: Uint8Array = new util.TextEncoder().encodeInto(timestamp);
  // 本机实现中 doFinal 输出已是 密文||tag(16)，GcmParamsSpec.authTag 不回填
  const encrypted: cryptoFramework.DataBlob = await cipher.doFinal({ data: plain });

  const merged: Uint8Array = new Uint8Array(nonce.length + encrypted.data.length);
  merged.set(nonce, 0);
  merged.set(encrypted.data, nonce.length);
  return urlSafeBase64(merged);
}

// 注册接口请求头：X-Device 为持久安装 ID，X-USER 为服务器 deviceKey
export async function signedHeaders(deviceId: string, serverKey: string): Promise<Record<string, string>> {
  const signature: string = await signTimestamp(`${Math.floor(Date.now() / 1000)}`, activeKey());
  const headers: Record<string, string> = {};
  headers['Content-Type'] = 'application/json';
  headers['User-Agent'] = noletUserAgent();
  headers['X-Device'] = deviceId;
  headers['X-USER'] = serverKey;
  headers['Authorization'] = signature;
  headers['X-Signature'] = signature;
  return headers;
}
