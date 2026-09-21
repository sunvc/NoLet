// @keepTs
// @ts-nocheck
export declare class TokenInfo {
    private token;
    private validPeriod;
    /**
     * 构造方法，给定一些默认值，需要改变时，通过set方法设置
     */
    constructor();
    getToken(): string;
    setToken(value: string): void;
    getValidPeriod(): number;
    setValidPeriod(value: number): void;
}
