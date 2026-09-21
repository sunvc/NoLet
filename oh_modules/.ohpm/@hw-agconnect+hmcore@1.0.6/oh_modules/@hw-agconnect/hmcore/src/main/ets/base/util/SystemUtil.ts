import deviceInfo from '@ohos.deviceInfo';
import display from '@ohos.display';
import bundle from '@ohos.bundle';
import storage from '@ohos.statfs';
import bundleManager from '@ohos.bundle.bundleManager';
import { Logger } from '../log/Logger';
import common from '@ohos.app.ability.common';

export class SystemUtil {
  /**
   * 获取应用的包名
   */
  static getPackageName(context: common.Context): string {
    return context.applicationInfo?.name;
  }

  static async getAppVersion(context: common.Context): Promise<string> {
    let result = '';
    try {
      let bundleName = SystemUtil.getPackageName(context);
      if (bundleName) {
        let bundleInfo = await bundle.getBundleInfo(bundleName, 0);
        result = bundleInfo?.versionName;
        if (!result) {
          let bundleFlags = bundleManager.BundleFlag.GET_BUNDLE_INFO_DEFAULT;
          let bundleInfoForSelf = await bundleManager.getBundleInfoForSelf(bundleFlags);
          result = bundleInfoForSelf?.versionName;
        }
      }
    } catch (e) {
      Logger.warn('SystemUtil', 'get app version error:' + e?.message);
    }
    return Promise.resolve(result);
  }

  /**
   * 返回AGC格式的系统名称
   * OpenHarmony 3.2.6.5(Beta2)
   */
  static getOsFullName(): string {
    //OpenHarmony-3.2.6.5(Beta2)
    let fullname = deviceInfo.osFullName.split('-');
    if (fullname && fullname.length >= 1) {
      return fullname[0] + ' ' + fullname[1];
    }
    return '';
  }

  /**
   * 返回AGC格式的系统名称
   * OpenHarmony
   */
  static getOsName(): string {
    let fullname = SystemUtil.getOsFullName();
    let index = fullname.indexOf(' ');
    if (index > 0) {
      return fullname.substring(0, index);
    }
    return fullname;
  }

  /**
   * 返回系统的版本号
   * 3.2.6.5(Beta2)
   * @returns
   */
  static getOsFullVersion(): string {
    let fullname = deviceInfo.osFullName.split('-');
    if (fullname && fullname.length >= 1) {
      return fullname[1];
    }
    return '';
  }

  /**
   * 返回系统的版本号，不包含（beta）
   * 3.2.6.5
   * @returns
   */
  static getOsVersion(): string {
    let fullname: string = SystemUtil.getOsFullVersion();
    if (fullname && fullname.length >= 1 ) {
      let index = fullname.indexOf('(');
      if (index > 0) {
        return fullname.substring(0, index);
      }
      return fullname;
    }
    return '';
  }

  /**
   * 返回设备厂家名称
   * HUAWEI
   * @returns
   */
  static getManufacture(): string {
    return deviceInfo.manufacture;
  }

  /**
   * 返回设备品牌名称
   * HUAWEI MATE 30 PRO
   * @returns
   */
  static getBrand(): string {
    return deviceInfo.brand;
  }

  /**
   * 返回认证型号
   * LIO-AL00
   * @returns
   */
  static getProductModel(): string {
    return deviceInfo.productModel;
  }

  /**
   * 返回产品版本
   * OpenHarmony-3.2.6.5(Beta2)
   * @returns
   */
  static getDisplayVersion(): string {
    return deviceInfo.productModel;
  }

  /**
   * 返回默认屏幕信息
   * width，height，rotation
   * @returns
   */
  static async getDefaultDisplay(): Promise<any> {
    let displayInfo;
    try {
      displayInfo = display.getDefaultDisplay();
    } catch (e) {
      displayInfo = {
        width: 0,
        height: 0,
        rotation: 0
      };
    }
    return displayInfo;
  }

  /**
   * 返回空闲存储空间
   * @returns
   */
  static async getFreeBytes(filesDir: string): Promise<number> {
    let freeBytes;
    try {
      freeBytes = storage.getFreeBytes(filesDir);
    } catch (e) {
      freeBytes = 0;
    }
    return freeBytes;
  }
}
