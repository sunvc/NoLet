import { util } from '@kit.ArkTS';
import { Domap, DomapTriple } from '../tools/Domap';

// 对应 iOS CryptoModelConfig：AES-GCM 签名密钥配置。
// 导入/导出串由 Domap base64 混淆，非明文 "mode,key,iv"。
@ObservedV2
export class CryptoConfig {
  @Trace id: string = '';
  // 密钥位数：16=AES128 / 24=AES192 / 32=AES256
  @Trace algorithm: number = 32;
  @Trace mode: string = CryptoMode.GCM;
  @Trace key: string = '';
  @Trace iv: string = '';
  // 系统内置保留项：与 iOS Domap 默认签名配置一致，禁止编辑和删除
  @Trace builtin: boolean = false;
}

export class CryptoAlgorithm {
  static readonly AES128: number = 16;
  static readonly AES192: number = 24;
  static readonly AES256: number = 32;

  static algName(len: number): string {
    if (len === CryptoAlgorithm.AES128) return 'AES128';
    if (len === CryptoAlgorithm.AES192) return 'AES192';
    return 'AES256';
  }

  static readonly ALL: number[] = [16, 24, 32];
}

export class CryptoMode {
  static readonly GCM: string = 'GCM';
  static readonly ALL: string[] = ['GCM'];
}

const ALNUM: string = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';

// iOS Domap.KEY / IV：内置默认签名配置（Domap.createKeyOrIV 推导值）
export const DEFAULT_KEY: string = '8FdEckIGyWKKSZmFx1oMLIR6LBEndYau';
export const DEFAULT_IV: string = 'qBeIIG8DFHIEdm7L';

export class CryptoConfigFactory {
  static randomString(length: number): string {
    let out: string = '';
    for (let i = 0; i < length; i++) {
      out += ALNUM.charAt(Math.floor(Math.random() * ALNUM.length));
    }
    return out;
  }

  // 内置默认配置（与 iOS Domap.data 一致）；系统保留，不可编辑、删除
  static defaultConfig(): CryptoConfig {
    const c = new CryptoConfig();
    c.id = util.generateRandomUUID(false);
    c.algorithm = CryptoAlgorithm.AES256;
    c.mode = CryptoMode.GCM;
    c.key = DEFAULT_KEY;
    c.iv = DEFAULT_IV;
    c.builtin = true;
    return c;
  }

  // 新建随机配置（对应 iOS creteNewModel：32 位随机 key，16 位随机 iv）
  static newRandomConfig(): CryptoConfig {
    const c = new CryptoConfig();
    c.id = util.generateRandomUUID(false);
    c.algorithm = CryptoAlgorithm.AES256;
    c.mode = CryptoMode.GCM;
    c.key = CryptoConfigFactory.randomString(32);
    c.iv = CryptoConfigFactory.randomString(16);
    return c;
  }

  // 与现有配置是否重复：模式、KEY、IV 完全一致即视为同一项（导入时去重）
  static existsLike(configs: CryptoConfig[], target: CryptoConfig): boolean {
    return configs.some((c: CryptoConfig): boolean =>
      c.mode === target.mode && c.key === target.key && c.iv === target.iv);
  }

  // 导出混淆串（Domap base64）；配置非法返回 null
  static obfuscate(c: CryptoConfig): string | null {
    return Domap.obfuscate(c.mode, c.key, c.iv);
  }

  // 解析混淆串；非法返回 null（对应 iOS init?(inputText:)）
  static deobfuscate(text: string): CryptoConfig | null {
    const triple: DomapTriple | null = Domap.deobfuscate(text.trim());
    if (triple === null) return null;
    if (CryptoMode.ALL.indexOf(triple.mode) < 0) return null;
    if (CryptoAlgorithm.ALL.indexOf(triple.key.length) < 0) return null;
    const c = new CryptoConfig();
    c.id = util.generateRandomUUID(false);
    c.algorithm = triple.key.length;
    c.mode = triple.mode;
    c.key = triple.key;
    c.iv = triple.iv;
    return c;
  }
}
