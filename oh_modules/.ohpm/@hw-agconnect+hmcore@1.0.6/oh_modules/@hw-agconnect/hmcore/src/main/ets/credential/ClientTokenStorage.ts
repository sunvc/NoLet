import DefaultCrypto from '../base/crypto/DefaultCrypto';
import { Preferences } from '../base/datastore/Preference';
import { getCore } from '../core/hmcore';
import { CredentialInfo } from './CredentialInfo';

const STORAGE_CREDENTIAL_FILE: string = 'ohos_agc_credential_aegis';

export class ClientTokenStorage {
  private identifier: string;
  private key: string = 'ohos_agc_credential';

  private credentialInfo: CredentialInfo | null = null;

  constructor(region: string) {
    this.identifier = region;
    this.key = this.key + '_' + this.identifier;
  }

  async getToken(): Promise<CredentialInfo | null> {
    if (this.credentialInfo != null) {
      return Promise.resolve(this.credentialInfo);
    }

    let crypto = await DefaultCrypto.get();
    let infoString = await Preferences.get(
      getCore().context,
      STORAGE_CREDENTIAL_FILE,
      this.key,
      crypto
    );
    if (infoString == null || infoString == '') {
      return Promise.resolve(null);
    }
    try {
      let info = JSON.parse(infoString);
      this.credentialInfo = new CredentialInfo(
        info.expiration,
        info.tokenString,
        info.lastRefreshTime
      );
      return Promise.resolve(this.credentialInfo);
    } catch (e) {
      // prevent JSON.parse error
      return Promise.resolve(null);
    }
  }

  async putToken(credentialInfo: CredentialInfo): Promise<void> {
    try {
      this.credentialInfo = credentialInfo;
      let crypto = await DefaultCrypto.get();
      await Preferences.put(
        getCore().context,
        STORAGE_CREDENTIAL_FILE,
        this.key,
        JSON.stringify(credentialInfo),
        crypto
      );
    } catch (e) {}
    return Promise.resolve();
  }
}
