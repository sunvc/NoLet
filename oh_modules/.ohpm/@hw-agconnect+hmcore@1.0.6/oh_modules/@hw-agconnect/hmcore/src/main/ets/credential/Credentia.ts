import { Logger } from '../base/log/Logger';
import { AGCError } from '../error/AGCError';
import { Token } from '../core';
import { Backend } from '../server/Backend';
import { ClientTokenRequest } from './ClientTokenRequest';
import { ClientTokenStorage } from './ClientTokenStorage';
import { CredentialInfo } from './CredentialInfo';
import { TokenImpl } from './TokenImpl';

const TAG = 'Credential';

class Credential {
  private clientTokenStorage: ClientTokenStorage;

  async getToken(forceRefresh: boolean, region: string): Promise<Token> {
    if (!this.clientTokenStorage) {
      this.clientTokenStorage = new ClientTokenStorage(region);
    }
    let credentialInfo = await this.clientTokenStorage.getToken();
    if (credentialInfo != null && credentialInfo.isValid()) {
      if (forceRefresh && credentialInfo.allowRefresh()) {
        Logger.info(TAG, 'force Refresh client token');
      } else {
        Logger.info(TAG, 'get client token from local');
        return Promise.resolve(
          new TokenImpl(credentialInfo.expiration, credentialInfo.tokenString)
        );
      }
    }

    let response = await Backend.post(new ClientTokenRequest(region));
    try {
      let result = JSON.parse(response);
      // client Token 获取成功时，不存在ret字段
      if (result.ret) {
        Logger.error(TAG, 'get client token error');
        return Promise.reject(new AGCError(result.ret.code, result.ret.msg));
      } else {
        Logger.info(TAG, 'update client token');
        credentialInfo = new CredentialInfo(
          result.expires_in,
          result.access_token,
          new Date().getTime()
        );
        await this.clientTokenStorage.putToken(credentialInfo);
        return Promise.resolve(new TokenImpl(credentialInfo.expiration, credentialInfo.tokenString));
      }
    } catch (e) {
      Logger.error(TAG, 'parse json error' + JSON.stringify(e));
      return Promise.resolve(null);
    }
  }
}

export default new Credential();
