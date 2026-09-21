// @keepTs
// @ts-nocheck
import display from '@ohos.display';
import common from '@ohos.app.ability.common';
export declare class SystemUtil {
    /**
     * 获取应用的包名
     */
    static getPackageName(context: common.Context): string;
    static getAppVersion(): Promise<string>;
    /**
     * 返回AGC格式的系统名称
     * OpenHarmony 3.2.6.5(Beta2)
     */
    static getOsFullName(): string;
    /**
     * 返回AGC格式的系统名称
     * OpenHarmony
     */
    static getOsName(): string;
    /**
     * 返回系统的版本号
     * 3.2.6.5(Beta2)
     * @returns
     */
    static getOsFullVersion(): string;
    /**
     * 返回系统的版本号，不包含（beta）
     * 3.2.6.5
     * @returns
     */
    static getOsVersion(): string;
    /**
     * 返回设备品牌名称
     * HUAWEI MATE 30 PRO
     * @returns
     */
    static getBrand(): string;
    /**
     * 返回认证型号
     * LIO-AL00
     * @returns
     */
    static getProductModel(): string;
    /**
     * 返回产品版本
     * OpenHarmony-3.2.6.5(Beta2)
     * @returns
     */
    static getDisplayVersion(): string;
    /**
     * 返回默认屏幕信息
     * width，height，rotation
     * @returns
     */
    static getDefaultDisplay(): Promise<display.Display>;
}
