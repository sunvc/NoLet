import { http } from '@kit.NetworkKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { ServerInfo } from './ServerInfo';
import { BaseResponse, DeviceInfo } from './NetworkModel';
import { signedHeaders } from '../tools/Signature';

const DOMAIN = 0x0000;
const TAG = 'ServerRegistrar';
const TIMEOUT_MS = 15000;

// 服务器注册（对应 iOS AppManager 的 register/restore/registers）：
// - claimKey：GET  {url}/register/{deviceKey}，认领或校验设备 key
// - register： POST {url}/register，上报 DeviceInfo（推送 token 等），服务端可下发 key/core
// - registerAll：启动时并发重注册全部服务器
// 网络异常不抛错，返回 status=-1 的副本，与 iOS catch 后置离线一致。
export class ServerRegistrar {
  static readonly DEFAULT_SERVER: string = 'https://wzs.app';
  private deviceId: string = '';

  init(deviceId: string): void {
    this.deviceId = deviceId;
  }

  // GET /register/{deviceKey}，服务端 code 2xx 且 message=success 才算成功
  async claimKey(baseUrl: string, deviceKey: string): Promise<boolean> {
    const req = http.createHttp();
    let headers: Record<string, string>;
    try {
      headers = await signedHeaders(this.deviceId, deviceKey);
    } catch (e) {
      const err = e as BusinessError;
      hilog.error(DOMAIN, TAG, `claimKey signing failed for ${baseUrl}: ${err.code} ${err.message}`);
      return false;
    }
    try {
      const resp = await req.request(`${baseUrl}/register/${encodeURIComponent(deviceKey)}`, {
        method: http.RequestMethod.GET,
        header: headers,
        connectTimeout: TIMEOUT_MS,
        readTimeout: TIMEOUT_MS,
        // 固定 HTTP/1.1：个别服务器/网关对协商 h2 的 TLS 指纹直接断连（设备侧报 2300999）
        usingProtocol: http.HttpProtocol.HTTP1_1,
      });
      const body = JSON.parse(resp.result as string) as BaseResponse<string>;
      const ok: boolean = body.code >= 200 && body.code <= 299 && body.message === 'success';
      if (!ok) hilog.error(DOMAIN, TAG, `claimKey rejected: ${body.code} ${body.message}`);
      return ok;
    } catch (e) {
      const err = e as BusinessError;
      hilog.error(DOMAIN, TAG, `claimKey failed for ${baseUrl}: ${err.code} ${err.message}`);
      return false;
    } finally {
      req.destroy();
    }
  }

  // POST /register。返回传入 server 的副本（服务端下发新 key 时覆盖），失败时 status=-1
  async register(
    server: ServerInfo,
    token: string,
    talk: string = '',
    location: string = '',
    voip: string = '',
  ): Promise<ServerInfo> {
    const result: ServerInfo = new ServerInfo();
    result.id = server.id;
    result.url = server.url;
    result.key = server.key;
    result.group = server.group;

    const info = new DeviceInfo();
    info.key = server.key;
    info.token = token;
    if (talk) info.talk = talk;
    if (location) info.location = location;
    if (voip) info.voip = voip;
    if (server.group) info.group = server.group;

    const req = http.createHttp();
    let headers: Record<string, string>;
    try {
      headers = await signedHeaders(this.deviceId, server.key);
    } catch (e) {
      const err = e as BusinessError;
      hilog.error(DOMAIN, TAG, `register signing failed for ${server.url}: ${err.code} ${err.message}`);
      result.status = -1;
      return result;
    }
    try {
      const resp = await req.request(`${server.url}/register`, {
        method: http.RequestMethod.POST,
        header: headers,
        extraData: JSON.stringify(info),
        connectTimeout: TIMEOUT_MS,
        readTimeout: TIMEOUT_MS,
        // 固定 HTTP/1.1：个别服务器/网关对协商 h2 的 TLS 指纹直接断连（设备侧报 2300999）
        usingProtocol: http.HttpProtocol.HTTP1_1,
      });
      let body: BaseResponse<DeviceInfo>;
      try {
        body = JSON.parse(resp.result as string) as BaseResponse<DeviceInfo>;
      } catch {
        const headers: Record<string, string> = resp.header as Record<string, string>;
        hilog.error(DOMAIN, TAG,
          `register non-JSON response from ${server.url}: HTTP ${resp.responseCode} ${headers['content-type']} ` +
          `${String(resp.result).substring(0, 200)}`);
        result.status = -1;
        return result;
      }
      if (body.code >= 200 && body.code <= 299 && body.data) {
        if (body.data.key) result.key = body.data.key;
        result.status = body.data.core ?? 1;
      } else {
        hilog.error(DOMAIN, TAG, `register rejected by ${server.url}: ${body.code} ${body.message}`);
        result.status = -1;
      }
    } catch (e) {
      const err = e as BusinessError;
      hilog.error(DOMAIN, TAG, `register request failed for ${server.url}: ${err.code} ${err.message}`);
      result.status = -1;
    } finally {
      req.destroy();
    }
    return result;
  }

  // 并发重新注册全部服务器，返回结果顺序与入参一致
  async registerAll(servers: ServerInfo[], token: string): Promise<ServerInfo[]> {
    return Promise.all(servers.map((s: ServerInfo): Promise<ServerInfo> => this.register(s, token)));
  }
}

export const serverRegistrar: ServerRegistrar = new ServerRegistrar();
