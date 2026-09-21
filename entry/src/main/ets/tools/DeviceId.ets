import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { util } from '@kit.ArkTS';

// 对应 iOS IDManager：UUIDv4 字节按 base58（去易混字符）编码得到设备 ID，
// Preferences 持久化，跨启动稳定。作为注册请求的 X-Device 与默认服务器的 deviceKey。

const PREFS_NAME: string = 'device_prefs';
const KEY_ID: string = 'id';
const ALPHABET: string = '23456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';

let cachedId: string = '';

function base58Encode(input: Uint8Array): string {
  const digits: number[] = [];
  for (let i = 0; i < input.length; i++) {
    let carry: number = input[i];
    for (let j = 0; j < digits.length; j++) {
      carry += digits[j] * 256;
      digits[j] = carry % 58;
      carry = Math.floor(carry / 58);
    }
    while (carry > 0) {
      digits.push(carry % 58);
      carry = Math.floor(carry / 58);
    }
  }
  let result: string = '';
  for (let k = 0; k < input.length && input[k] === 0; k++) {
    result += ALPHABET.charAt(0);
  }
  for (let i = digits.length - 1; i >= 0; i--) {
    result += ALPHABET.charAt(digits[i]);
  }
  return result;
}

function uuidBytes(uuid: string): Uint8Array {
  const hex: string = uuid.replace(/-/g, '');
  const bytes: Uint8Array = new Uint8Array(16);
  for (let i = 0; i < 16; i++) {
    bytes[i] = Number.parseInt(hex.substring(i * 2, i * 2 + 2), 16);
  }
  return bytes;
}

export async function getDeviceId(context: common.Context): Promise<string> {
  if (cachedId) return cachedId;

  const prefs = await preferences.getPreferences(context, PREFS_NAME);
  let id: string = prefs.getSync(KEY_ID, '') as string;
  if (!id) {
    const uuid: string = util.generateRandomUUID(false);
    id = base58Encode(uuidBytes(uuid));
    await prefs.put(KEY_ID, id);
    await prefs.flush();
  }
  cachedId = id;
  return id;
}
