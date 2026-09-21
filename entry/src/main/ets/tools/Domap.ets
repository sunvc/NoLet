import { util } from '@kit.ArkTS';

// 最精简的配置串示例：把 (mode, key, iv) 用 '|' 拼接后做 base64 编码，
// 得到可分享/导入的加密配置串，deobfuscate 反向还原。
// key/iv 由本应用生成、仅含字母数字，'|' 不会出现在取值中。
// 仅作示例用，不再与 iOS 端的置换混淆互通。
export interface DomapTriple {
  mode: string; // 模式名（大写，如 GCM）
  key: string;  // 密钥：16/24/32 位对应 AES-128/192/256
  iv: string;   // 16 位初始向量
}

export class Domap {
  // 混淆：base64("mode|key|iv")；参数非法返回 null
  static obfuscate(mode: string, key: string, iv: string): string | null {
    if (mode.length !== 3 || key.length < 16 || iv.length !== 16) return null;
    const plain: string = `${mode}|${key}|${iv}`;
    return new util.Base64Helper().encodeToStringSync(new util.TextEncoder().encodeInto(plain));
  }

  // 反混淆：解码 base64 后按 '|' 拆出 (mode, key, iv)；非法返回 null
  static deobfuscate(text: string): DomapTriple | null {
    let plain: string;
    try {
      plain = util.TextDecoder.create('utf-8')
        .decodeToString(new util.Base64Helper().decodeSync(text.trim()));
    } catch {
      return null;
    }
    const parts: string[] = plain.split('|');
    if (parts.length !== 3) return null;
    const mode: string = parts[0];
    const key: string = parts[1];
    const iv: string = parts[2];
    if (mode.length !== 3 || key.length < 16 || iv.length !== 16) return null;
    return { mode, key, iv };
  }
}
