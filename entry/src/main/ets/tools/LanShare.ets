import { socket, connection } from '@kit.NetworkKit';
import { cryptoFramework } from '@kit.CryptoArchitectureKit';
import { util } from '@kit.ArkTS';
import { BusinessError } from '@kit.BasicServicesKit';
import { deviceInfo } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { appStore } from '../store/AppStore';

const DOMAIN: number = 0x0000;
const TAG: string = 'LanShare';

// 局域网快传协议（纯 UDP 广播，无需配对/连接）：
// 每个数据包为 JSON：
//   m  魔数 NOLETLAN   v 协议版本   id 消息id（接收端分片重组与去重）
//   ts 毫秒时间戳  dev 发送设备名
//   n 分片总数  i 当前分片下标（从0开始）
//   iv base64(12字节 nonce)  d base64(GCM 密文||tag)
// 每个分片是独立加密的原文 UTF-8 片段，接收端收齐后按 i 拼接；
// 整组分片重复广播 ROUNDS 轮抗丢包。
const MAGIC: string = 'NOLETLAN';
const VERSION: number = 1;
export const LAN_PORT: number = 39876;
// 单片原文 700 字节（base64 与 JSON 开销后单包仍远低于 1400 字节安全载荷）
const CHUNK_BYTES: number = 700;
const MAX_CHUNKS: number = 32;
const ROUNDS: number = 3;
const ROUND_GAP_MS: number = 120;

export type LanShareFailReason = 'no_code' | 'no_wifi' | 'too_large' | 'failed';

export interface LanShareResult {
  ok: boolean;
  chunks: number;
  reason?: LanShareFailReason;
}

interface LanPacket {
  m: string;
  v: number;
  id: string;
  ts: number;
  dev: string;
  n: number;
  i: number;
  iv: string;
  d: string;
}

// 6 位数字接收码
export function generateLanCode(): string {
  let code: string = '';
  for (let i = 0; i < 6; i++) {
    code += Math.floor(Math.random() * 10).toString();
  }
  return code;
}

function base64(bytes: Uint8Array): string {
  return new util.Base64Helper().encodeToStringSync(bytes);
}

// 接收码 → SHA-256 摘要，作为 AES-256-GCM 密钥（与 Mac 端 CryptoKit 约定一致）
async function deriveKey(code: string): Promise<cryptoFramework.SymKey> {
  const md = cryptoFramework.createMd('SHA256');
  md.update({ data: new util.TextEncoder().encodeInto(code) });
  const digest: cryptoFramework.DataBlob = await md.digest();
  const generator = cryptoFramework.createSymKeyGenerator('AES256');
  return generator.convertKey({ data: digest.data });
}

// GCM 加密一片：输出 nonce(12) || 密文 || tag(16)（本机 doFinal 输出已含 tag）
async function encryptChunk(key: cryptoFramework.SymKey, plain: Uint8Array): Promise<Uint8Array> {
  const nonce: Uint8Array = new Uint8Array(12);
  for (let i = 0; i < 12; i++) {
    nonce[i] = Math.floor(Math.random() * 256);
  }
  const cipher = cryptoFramework.createCipher('AES256|GCM|NoPadding');
  const params: cryptoFramework.GcmParamsSpec = {
    algName: 'GcmParamsSpec',
    iv: { data: nonce },
    aad: { data: new Uint8Array(0) },
    authTag: { data: new Uint8Array(16) }
  };
  await cipher.init(cryptoFramework.CryptoMode.ENCRYPT_MODE, key, params);
  const out: cryptoFramework.DataBlob = await cipher.doFinal({ data: plain });
  const merged: Uint8Array = new Uint8Array(nonce.length + out.data.length);
  merged.set(nonce, 0);
  merged.set(out.data, nonce.length);
  return merged;
}

// 当前默认网络是否走 Wi-Fi（蜂窝/VPN 下广播到不了家庭局域网）
async function isOnWifi(): Promise<boolean> {
  try {
    const net = await connection.getDefaultNet();
    if (!net || net.netId === 0) {
      hilog.info(DOMAIN, TAG, 'no default network');
      return false;
    }
    const cap = await connection.getNetCapabilities(net);
    const onWifi: boolean = cap.bearerTypes.indexOf(connection.NetBearType.BEARER_WIFI) >= 0;
    hilog.info(DOMAIN, TAG, `default net=${net.netId} bearer=${cap.bearerTypes.join(',')} wifi=${onWifi}`);
    return onWifi;
  } catch (e) {
    hilog.error(DOMAIN, TAG, `network check failed: ${(e as BusinessError).message}`);
    return false;
  }
}

// 由 IPv4 地址和前缀长度算子网定向广播地址（如 192.168.1.0/24 → 192.168.1.255）
function directedBroadcast(ip: string, prefix: number): string {
  if (prefix <= 0 || prefix >= 31) return '';
  const parts: string[] = ip.split('.');
  if (parts.length !== 4) return '';
  const bytes: number[] = parts.map((p: string): number => Number(p));
  if (bytes.some((n: number): boolean => Number.isNaN(n) || n < 0 || n > 255)) return '';
  const hostBits: number = 32 - prefix;
  const mask: number = (0xFFFFFFFF << hostBits) >>> 0;
  const addr: number = ((bytes[0] << 24) | (bytes[1] << 16) | (bytes[2] << 8) | bytes[3]) >>> 0;
  const bcast: number = (addr | (~mask >>> 0)) >>> 0;
  return [(bcast >>> 24) & 255, (bcast >>> 16) & 255, (bcast >>> 8) & 255, bcast & 255].join('.');
}

async function broadcastTargets(): Promise<string[]> {
  const targets: string[] = ['255.255.255.255'];
  try {
    const net = await connection.getDefaultNet();
    if (net && net.netId !== 0) {
      const props = await connection.getConnectionProperties(net);
      props.linkAddresses.forEach((la: connection.LinkAddress): void => {
        const ip: string = la.address?.address ?? '';
        if (ip.indexOf('.') > 0) {
          const bcast: string = directedBroadcast(ip, la.prefixLength);
          if (bcast && targets.indexOf(bcast) < 0) targets.push(bcast);
        }
      });
    }
  } catch (e) {
    hilog.warn(DOMAIN, TAG, `directed broadcast resolve failed: ${(e as BusinessError).message}`);
  }
  return targets;
}

function sleep(ms: number): Promise<void> {
  return new Promise((resolve: () => void): void => {
    setTimeout(resolve, ms);
  });
}

// 把文本分片加密后 UDP 广播给同网段监听端。失败原因通过 result.reason 返回，不抛异常
export async function shareLanText(text: string): Promise<LanShareResult> {
  const state = appStore.getState();
  const code: string = state.lanCode.trim();
  if (!code) {
    return { ok: false, chunks: 0, reason: 'no_code' };
  }
  const raw: Uint8Array = new util.TextEncoder().encodeInto(text);
  if (raw.byteLength === 0) {
    return { ok: false, chunks: 0, reason: 'failed' };
  }
  if (raw.byteLength > CHUNK_BYTES * MAX_CHUNKS) {
    return { ok: false, chunks: 0, reason: 'too_large' };
  }
  if (!await isOnWifi()) {
    return { ok: false, chunks: 0, reason: 'no_wifi' };
  }

  const key = await deriveKey(code);
  const total: number = Math.ceil(raw.byteLength / CHUNK_BYTES);
  const id: string = util.generateRandomUUID(false);
  let deviceName: string = 'HarmonyOS';
  try {
    deviceName = deviceInfo.marketName || deviceName;
  } catch (e) {
    hilog.warn(DOMAIN, TAG, `device name failed: ${(e as BusinessError).message}`);
  }

  const packets: string[] = [];
  for (let i = 0; i < total; i++) {
    const start: number = i * CHUNK_BYTES;
    const part: Uint8Array = raw.subarray(start, Math.min(start + CHUNK_BYTES, raw.byteLength));
    const sealed: Uint8Array = await encryptChunk(key, part);
    const packet: LanPacket = {
      m: MAGIC,
      v: VERSION,
      id,
      ts: Date.now(),
      dev: deviceName,
      n: total,
      i,
      // sealed 首 12 字节是 nonce，其余是密文||tag
      iv: base64(sealed.subarray(0, 12)),
      d: base64(sealed.subarray(12))
    };
    packets.push(JSON.stringify(packet));
  }

  const targets: string[] = await broadcastTargets();
  const udp = socket.constructUDPSocketInstance();
  try {
    await udp.bind({ address: '0.0.0.0', port: 0, family: 1 });
    await udp.setExtraOptions({ broadcast: true });
    // 整组重复广播多轮，抗单包丢失
    for (let round = 0; round < ROUNDS; round++) {
      for (let i = 0; i < packets.length; i++) {
        for (let t = 0; t < targets.length; t++) {
          await udp.send({
            data: packets[i],
            address: { address: targets[t], port: LAN_PORT, family: 1 }
          });
        }
      }
      if (round < ROUNDS - 1) {
        await sleep(ROUND_GAP_MS);
      }
    }
    hilog.info(DOMAIN, TAG, `broadcast ${raw.byteLength} bytes in ${total} chunks to ${targets.join(',')}`);
    return { ok: true, chunks: total };
  } catch (e) {
    hilog.error(DOMAIN, TAG, `broadcast failed: ${(e as BusinessError).message}`);
    return { ok: false, chunks: 0, reason: 'failed' };
  } finally {
    try {
      await udp.close();
    } catch (e) {
      hilog.warn(DOMAIN, TAG, `udp close failed: ${(e as BusinessError).message}`);
    }
  }
}
