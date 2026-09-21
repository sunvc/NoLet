import { cryptoFramework } from '@kit.CryptoArchitectureKit';
import { util } from '@kit.ArkTS';

// 加密推送解密（对应 iOS CryptoManager.decrypt）：
// 密文为 base64（兼容 URL-safe），字节布局 12 字节 nonce + 密文 + 16 字节 GCM tag；
// 密钥长度决定 AES128/192/256，取用户加密配置列表中对应下标的 key。

const NONCE_LEN: number = 12;
const TAG_LEN: number = 16;
const VALID_KEY_LENGTHS: number[] = [16, 24, 32];

// 标准 base64 与 URL-safe base64 都兼容（-/_、缺填充）
function decodeBase64(text: string): Uint8Array {
  let s: string = text.trim().replace(/-/g, '+').replace(/_/g, '/').replace(/\s/g, '');
  const pad: number = s.length % 4;
  if (pad) s += '='.repeat(4 - pad);
  return new util.Base64Helper().decodeSync(s);
}

// 解密成功返回 UTF-8 明文（约定为 JSON 字符串）；密钥非法、base64 非法或验签失败均返回 null
export async function decryptCiphertext(b64: string, key: string): Promise<string | null> {
  if (VALID_KEY_LENGTHS.indexOf(key.length) < 0) return null;

  let raw: Uint8Array;
  try {
    raw = decodeBase64(b64);
  } catch {
    return null;
  }
  if (raw.length <= NONCE_LEN + TAG_LEN) return null;

  const alg: string = `AES${key.length * 8}`;
  try {
    const symKey = await cryptoFramework.createSymKeyGenerator(alg)
      .convertKey({ data: new util.TextEncoder().encodeInto(key) });

    const cipher = cryptoFramework.createCipher(`${alg}|GCM|NoPadding`);
    // 解密时 authTag 必须传入密文尾部的真实 tag（加密时不回填，解密时不填会验签失败）
    const params: cryptoFramework.GcmParamsSpec = {
      algName: 'GcmParamsSpec',
      iv: { data: raw.subarray(0, NONCE_LEN) },
      aad: { data: new Uint8Array(0) },
      authTag: { data: raw.subarray(raw.length - TAG_LEN) },
    };
    await cipher.init(cryptoFramework.CryptoMode.DECRYPT_MODE, symKey, params);

    const ct: Uint8Array = raw.subarray(NONCE_LEN, raw.length - TAG_LEN);
    const plain: cryptoFramework.DataBlob = await cipher.doFinal({ data: ct });
    return util.TextDecoder.create('utf-8').decodeToString(plain.data);
  } catch {
    return null;
  }
}
