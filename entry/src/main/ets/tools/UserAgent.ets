import { bundleManager } from '@kit.AbilityKit';
import deviceInfo from '@ohos.deviceInfo';
import { i18n } from '@kit.LocalizationKit';

// 服务端 GCM 中间件要求 User-Agent 以 NoLet 开头（大小写不敏感）。
// 格式对齐 iOS：NoLet/{版本} (Build {构建号}; {机型}; HarmonyOS {系统版本}; {地区}-{语言})
let cached: string = '';

export function noletUserAgent(): string {
  if (cached) return cached;

  const info = bundleManager.getBundleInfoForSelfSync(bundleManager.BundleFlag.GET_BUNDLE_INFO_DEFAULT);
  const versionName: string = info.versionName || '0.0';
  const versionCode: number = info.versionCode;
  const region: string = i18n.System.getSystemRegion() || 'CN';
  const language: string = (i18n.System.getSystemLanguage() || 'en').substring(0, 2);

  cached = `NoLet/${versionName} (Build ${versionCode}; ${deviceInfo.productModel}; ` +
    `HarmonyOS API ${deviceInfo.sdkApiVersion}; ${region}-${language})`;
  return cached;
}
