/**
 * Copyright (c) Huawei Technologies Co., Ltd. 2020-2020. All rights reserved.
 */

import { Logger } from '@hw-agconnect/hmcore';
import { Utils } from '../utils/Utils';
import { EntireEncryption } from './EntireEncryption';
import { EncryptInfo, EncryptionKeyStatus, EncryptResult } from '../sync/utils/EncryptInfo';
import { ErrorCode } from '../utils/ErrorCode';
import { ExceptionUtil } from '../utils/ExceptionUtil';
import { NaturalBaseRef } from '../base/NaturalBaseRef';
import { EntireEncryptInterval } from './EntireEncryptInterval';
import { NaturalCloudStorage } from '../storage/NaturalCloudStorage';
import { ConfigWrapper } from '../config/ConfigWrapper';
import { CloudDBCryptoJS } from './crypto/CloudDBCryptoJS';

const CryptoJS = CloudDBCryptoJS.getCryptoJS();

const KEY_SIZE = 8;
const DATA_KEY_TEXT_SIZE = 32;
const ROOT_KEY_ITERATION_COUNT = 100000;
const ROOT_KEY_TOKEN_ITERATION_COUNT = 10000;
// Weak check the user key by the character set that support capital letters, lowercase letters,
// numbers, special characters.
const LOW_REGEX_OF_USER_KEY = /^[0-9a-zA-Z`~!@#$%^&*()-_=+\\\\|\\[{\]};:'",<.>/? ]{6,32}$/;
// Strong check the user key by the character set that support capital letters, lowercase letters,
// numbers, special characters, the user key must have two character combinations at least.
const HIGH_REGEX_OF_USER_KEY =
  /^(?![0-9]+$)(?![a-z]+$)(?![A-Z]+$)(?![^a-zA-Z0-9]+$)[0-9a-zA-Z`~!@#$%^&*()-_=+\\\\|\\[{\]};:'",<.>? ]{8,32}$/;

export const SALT_SIZE = 16;
export const ENCODE_KEY_SIZE = 44;
export const TAG_SIZE = 16;
export const IV_SIZE = 12;
export const DATA_KEY_CIPHER_SIZE = IV_SIZE + TAG_SIZE + DATA_KEY_TEXT_SIZE;
const TAG = 'SecretKeyManager';

export interface CipherTextInfo {
  iv: Uint8Array;
  tag: Uint8Array;
  cipherText: Uint8Array;
}

export class SecretKeyManager {
  private userDataKeyInfo: UserDataKeyInfo;
  private entireEncryption: EntireEncryption;
  private cloudStorage: NaturalCloudStorage;
  private entireEncryptInterval: EntireEncryptInterval;

  constructor(naturalBaseRef: NaturalBaseRef) {
    this.userDataKeyInfo = new UserDataKeyInfo();
    this.cloudStorage = naturalBaseRef.getNaturalCloudStorage();
    this.entireEncryption = new EntireEncryption(naturalBaseRef);
    this.entireEncryptInterval = naturalBaseRef.getEntireEncryptInterval();
    this.entireEncryptInterval.saveSecretKeyManager(this);
  }

  public getEntireEncryption(): EntireEncryption {
    return this.entireEncryption;
  }

  public async setUserKey(userKey: string, needStrongCheck: boolean): Promise<void> {
    this.checkUserKeyFormat(userKey, false);
    const userId = await this.getUserId();
    const dataKeyInfo: UserDataKeyInfo = new UserDataKeyInfo();
    const saltFromCloudRet = await this.getSaltFromCloud();
    const ret: ErrorCode = saltFromCloudRet.resultCode;
    if (ret === ErrorCode.OK) {
      Logger.info(TAG, `setUserKey: user key has been created, need to verify it.`);
      dataKeyInfo.rootKeySalt = saltFromCloudRet.encryptInfo[0].firstSaltValue as Uint8Array;
      dataKeyInfo.rootKeyTokenSalt = saltFromCloudRet.encryptInfo[0].secondSaltValue as Uint8Array;
      await this.verifyUserKey(userId!, userKey, dataKeyInfo);
      this.entireEncryptInterval.setIntervalCleanKey(false);
    } else if (ret === ErrorCode.ENCRYPTION_SALT_EMPTY) {
      Logger.info(TAG, `setUserKey: the first time to set user key.`);
      await this.createUserKey(userId!, userKey, dataKeyInfo, needStrongCheck);
      this.entireEncryptInterval.setIntervalCleanKey(false);
    } else {
      Logger.error(TAG, `setUserKey: get salt failed, ret: ${ret}.`);
      this.clearDataKeyInfo();
      this.entireEncryption.clearUserKeysInfo();
      return Promise.reject(ret);
    }
    this.userDataKeyInfo.copy(dataKeyInfo);
  }

  public async modifyUserKey(
    userKey: string,
    userReKey: string,
    needStrongCheck: boolean
  ): Promise<void> {
    this.checkUserKeyFormat(userKey, false);
    this.checkUserKeyFormat(userReKey, needStrongCheck);
    const userId = await this.getUserId();
    const dataKeyInfo: UserDataKeyInfo = new UserDataKeyInfo();
    const saltFromCloudRet = await this.getSaltFromCloud();
    if (saltFromCloudRet.resultCode !== ErrorCode.OK) {
      Logger.error(TAG, `ModifyUserKey: get user salt failed.`);
      return Promise.reject(saltFromCloudRet.resultCode);
    }
    dataKeyInfo.rootKeySalt = saltFromCloudRet.encryptInfo[0].firstSaltValue as Uint8Array;
    dataKeyInfo.rootKeyTokenSalt = saltFromCloudRet.encryptInfo[0].secondSaltValue as Uint8Array;

    await this.modifyUserKeyInner(userId!, userKey, userReKey, dataKeyInfo);
    this.userDataKeyInfo.copy(dataKeyInfo);
    this.entireEncryptInterval.setIntervalCleanKey(false);
  }

  private async verifyUserKey(
    userId: string,
    userKey: string,
    dataKeyInfo: UserDataKeyInfo
  ): Promise<void> {
    this.clearDataKeyInfo();
    try {
      const dataKeys = await this.queryDataKeyCipher(userKey, dataKeyInfo);
      const dataKeyPlainText = dataKeys[0];
      const oldDataKeyPlainText = dataKeys[1];
      dataKeyInfo.userId = userId;
      const oldKeyLen = this.saveUserDataKey(dataKeyPlainText, oldDataKeyPlainText, dataKeyInfo);
      await this.entireEncryption.setKeys(
        userId,
        dataKeyPlainText,
        KEY_SIZE,
        oldDataKeyPlainText,
        oldKeyLen,
        dataKeyInfo.dataKeyVersion
      );
    } catch (ex) {
      Logger.error(TAG, `verifyUserKey: verify user key failed, ret: ${ex}.`);
      this.clearDataKeyInfo();
      this.entireEncryption.clearUserKeysInfo();
      return Promise.reject(ex);
    }
  }

  private async createUserKey(
    userId: string,
    userKey: string,
    dataKeyInfo: UserDataKeyInfo,
    needStrongCheck: boolean
  ): Promise<void> {
    // If strong verification is disabled, the verification does not need to be performed again.
    if (needStrongCheck) {
      this.checkUserKeyFormat(userKey, true);
    }
    this.clearDataKeyInfo();
    try {
      const dataKeyPlainText = this.generateRandom(DATA_KEY_TEXT_SIZE);
      await this.generateUserKey(userKey, dataKeyInfo, dataKeyPlainText);
      await this.InsertEncryptionInfoToCloud(dataKeyInfo);
      dataKeyInfo.userId = userId;
      const encodeDataKey = Utils.uint8ArrayToWordArray(dataKeyPlainText);
      dataKeyInfo.userDataKey = Utils.stringToUint8Array(this.encodeDataKey(encodeDataKey));
      dataKeyInfo.userDataKeyLen = ENCODE_KEY_SIZE;

      const oldDataKeyPlainText = new Uint8Array(KEY_SIZE);
      await this.entireEncryption.setKeys(
        dataKeyInfo.userId,
        dataKeyPlainText,
        KEY_SIZE,
        oldDataKeyPlainText,
        0,
        ++dataKeyInfo.dataKeyVersion
      );
    } catch (ex) {
      Logger.error(TAG, `createUserKey: create user key failed, ret: ${ex}.`);
      this.clearDataKeyInfo();
      this.entireEncryption.clearUserKeysInfo();
      return Promise.reject(ex);
    }
  }

  private async modifyUserKeyInner(
    userId: string,
    userKey: string,
    userReKey: string,
    dataKeyInfo: UserDataKeyInfo
  ) {
    this.clearDataKeyInfo();
    const dataKeys = await this.queryDataKeyCipher(userKey, dataKeyInfo);
    Logger.info(TAG, 'SecretKeyManager: query data key cipher success.');
    const dataKeyPlainText = dataKeys[0];
    const oldDataKeyPlainText = dataKeys[1];
    const oldRootKeyToken = dataKeyInfo.userRootKeyToken;
    await this.reGenerateUserKey(userReKey, dataKeyInfo, dataKeyPlainText, oldDataKeyPlainText);
    await this.updateEncryptionInfoToCloud(oldRootKeyToken, dataKeyInfo);
    dataKeyInfo.userId = userId;
    this.saveUserDataKey(dataKeyPlainText, oldDataKeyPlainText, dataKeyInfo);
  }

  private async queryDataKeyCipher(
    userKey: string,
    dataKeyInfo: UserDataKeyInfo
  ): Promise<[Uint8Array, Uint8Array]> {
    const userRootConfig = {
      keySize: KEY_SIZE,
      hasher: CryptoJS.algo.SHA256.create(),
      iterations: ROOT_KEY_ITERATION_COUNT
    };
    const userRootKeyWord = CryptoJS.PBKDF2(
      userKey,
      Utils.uint8ArrayToWordArray(dataKeyInfo.rootKeySalt),
      userRootConfig
    );
    if (Utils.isNullOrUndefined(userRootKeyWord)) {
      Logger.error(TAG, `queryDataKeyCipher: derive root key failed.`);
      return Promise.reject(ErrorCode.INTERNAL_ERROR);
    }
    dataKeyInfo.userRootKey = Utils.wordArrayToUint8Array(userRootKeyWord);
    dataKeyInfo.userRootKeyLen = KEY_SIZE;

    const userRootTokenConfig = {
      keySize: KEY_SIZE,
      hasher: CryptoJS.algo.SHA256.create(),
      iterations: ROOT_KEY_TOKEN_ITERATION_COUNT
    };
    const userRootKeyTokenWord = CryptoJS.PBKDF2(
      userRootKeyWord,
      Utils.uint8ArrayToWordArray(dataKeyInfo.rootKeyTokenSalt),
      userRootTokenConfig
    );
    if (Utils.isNullOrUndefined(userRootKeyTokenWord)) {
      Logger.error(TAG, `QueryDataKeyCipher: derive root key token failed.`);
      return Promise.reject(ErrorCode.INTERNAL_ERROR);
    }
    dataKeyInfo.userRootKeyToken = Utils.wordArrayToUint8Array(userRootKeyTokenWord);
    dataKeyInfo.userRootKeyTokenLen = KEY_SIZE;

    await this.queryDataKeyCipherFromCloud(dataKeyInfo);
    return await this.decryptQueryCipherText(dataKeyInfo);
  }

  private async reGenerateUserKey(
    userKey: string,
    dataKeyInfo: UserDataKeyInfo,
    dataKeyPlainText: Uint8Array,
    oldDataKeyPlainText: Uint8Array
  ): Promise<void> {
    await this.generateUserKey(userKey, dataKeyInfo, dataKeyPlainText);
    if (dataKeyInfo.userOldDataKeyCipherLen > 0) {
      const gcmIv = this.generateRandom(IV_SIZE);
      if (!gcmIv) {
        Logger.warn(TAG, 'reGenerateUserKey: random to generate gcmIv failed.');
        return Promise.reject(ErrorCode.INTERNAL_ERROR);
      }

      const dataKeyCipherInfo = await this.entireEncryption.aesGcm256Encrypt(
        oldDataKeyPlainText,
        dataKeyInfo.userRootKey,
        gcmIv
      );
      if (dataKeyCipherInfo.length <= 0) {
        Logger.warn(TAG, 'reGenerateUserKey: encrypt old dataKey failed.');
        return Promise.reject(ErrorCode.ENCRYPT_FAILED);
      }
      dataKeyInfo.userOldDataKeyCipher = {
        iv: gcmIv,
        tag: dataKeyCipherInfo.slice(DATA_KEY_TEXT_SIZE, dataKeyCipherInfo.length),
        cipherText: dataKeyCipherInfo.slice(0, DATA_KEY_TEXT_SIZE)
      };
    }
  }

  private async generateUserKey(
    userKey: string,
    dataKeyInfo: UserDataKeyInfo,
    dataKeyPlainText: Uint8Array
  ): Promise<void> {
    dataKeyInfo.rootKeySalt = this.generateRandom(SALT_SIZE);
    const rootKeyConfig = {
      keySize: KEY_SIZE,
      hasher: CryptoJS.algo.SHA256.create(),
      iterations: ROOT_KEY_ITERATION_COUNT
    };
    const rootKeySaltArray = Utils.uint8ArrayToWordArray(dataKeyInfo.rootKeySalt);
    const userRootKeyWord = await CryptoJS.PBKDF2(userKey, rootKeySaltArray, rootKeyConfig);
    if (Utils.isNullOrUndefined(userRootKeyWord)) {
      Logger.warn(TAG, `GenerateUserKey: derive root key failed.`);
      return Promise.reject(ErrorCode.INTERNAL_ERROR);
    }
    const userRootKey = Utils.wordArrayToUint8Array(userRootKeyWord);
    dataKeyInfo.userRootKey = userRootKey;
    dataKeyInfo.userRootKeyLen = KEY_SIZE;

    dataKeyInfo.rootKeyTokenSalt = this.generateRandom(SALT_SIZE);
    const rootKeyTokenConfig = {
      keySize: KEY_SIZE,
      hasher: CryptoJS.algo.SHA256.create(),
      iterations: ROOT_KEY_TOKEN_ITERATION_COUNT
    };
    const rootKeyTokenSaltArray = Utils.uint8ArrayToWordArray(dataKeyInfo.rootKeyTokenSalt);
    const userRootKeyTokenWord = await CryptoJS.PBKDF2(
      userRootKeyWord,
      rootKeyTokenSaltArray,
      rootKeyTokenConfig
    );
    if (Utils.isNullOrUndefined(userRootKeyTokenWord)) {
      Logger.warn(TAG, `GenerateUserKey: derive root key token failed.`);
      return Promise.reject(ErrorCode.INTERNAL_ERROR);
    }
    dataKeyInfo.userRootKeyToken = Utils.wordArrayToUint8Array(userRootKeyTokenWord);
    dataKeyInfo.userRootKeyTokenLen = KEY_SIZE;

    const gcmIv = this.generateRandom(IV_SIZE);
    if (!gcmIv) {
      Logger.warn(TAG, 'GenerateUserKey: random to generate gcmIv failed.');
      return Promise.reject(ErrorCode.INTERNAL_ERROR);
    }
    const userDataKeyCipherText = await this.entireEncryption.aesGcm256Encrypt(
      dataKeyPlainText,
      userRootKey,
      gcmIv
    );
    if (!userDataKeyCipherText) {
      Logger.warn(TAG, 'GenerateUserKey: encrypt dataKey failed.');
      return Promise.reject(ErrorCode.ENCRYPT_FAILED);
    }
    // slice userDataKeyCipherText
    dataKeyInfo.userDataKeyCipher = {
      iv: gcmIv,
      tag: userDataKeyCipherText.slice(DATA_KEY_TEXT_SIZE, userDataKeyCipherText.length),
      cipherText: userDataKeyCipherText.slice(0, DATA_KEY_TEXT_SIZE)
    };
  }

  public async onKeyStatusChanged(keyStatus: EncryptionKeyStatus): Promise<ErrorCode> {
    Logger.info(
      TAG,
      `onKeyStatusChanged: process call back with dataKey changed, keyStatus: ${keyStatus}`
    );
    const dataKeyStatus = keyStatus;
    if (
      dataKeyStatus !== EncryptionKeyStatus.INTERRUPT &&
      dataKeyStatus !== EncryptionKeyStatus.NORMAL
    ) {
      return Promise.resolve(ErrorCode.OK);
    }
    await this.queryDataKeyAfterReKey();
    return Promise.resolve(ErrorCode.OK);
  }

  private async queryDataKeyAfterReKey(): Promise<void> {
    await this.checkDataKeyCache();
    const inputInfo = new EncryptInfo();
    inputInfo.rootKeyToken = this.userDataKeyInfo.userRootKeyToken;
    const responseInfo = await this.cloudStorage.queryDataKeyCipherText(inputInfo);
    if (responseInfo.resultCode !== ErrorCode.OK) {
      Logger.warn(
        TAG,
        `queryDataKeyAfterReKey: query data key cipher failed from cloud,
             ret:${responseInfo.resultCode}.`
      );
      return Promise.reject(responseInfo.resultCode);
    }
    const outputInfo = responseInfo.encryptInfo[0];
    if (
      !outputInfo.dataKeyCipherText ||
      outputInfo.dataKeyCipherText.length !== DATA_KEY_CIPHER_SIZE
    ) {
      Logger.warn(
        TAG,
        `queryDataKeyAfterReKey: cloud saved dataKeyCipherText is invalid,
             dataKeyCipherText length: ${outputInfo.dataKeyCipherText?.length}`
      );
      return Promise.reject(ErrorCode.DATA_ENCRYPTION_KEY_INVALID);
    }
    if (this.userDataKeyInfo.dataKeyVersion < outputInfo.keyVersion) {
      await this.refreshDataKeyCache(outputInfo);
    }
  }

  public async checkKeyIfNetworkReconnect(): Promise<ErrorCode> {
    Logger.info(
      TAG,
      'CheckKeyIfNetworkReconnect: check userKey or dataKey changed after reconnect.'
    );
    await this.checkDataKeyCache();
    const inputInfo = new EncryptInfo();
    inputInfo.rootKeyToken = this.userDataKeyInfo.userRootKeyToken;
    const responseInfo = await this.cloudStorage.queryDataKeyCipherText(inputInfo);
    if (responseInfo.resultCode !== ErrorCode.OK) {
      Logger.warn(
        TAG,
        `CheckKeyIfNetworkReconnect: query data key cipher failed from cloud,
             ret:${responseInfo.resultCode}.`
      );
      return Promise.reject(responseInfo.resultCode);
    }
    return this.processDataKeyChangedByReconnect(responseInfo.encryptInfo[0]);
  }

  private async processDataKeyChangedByReconnect(encryptionInfo: EncryptInfo): Promise<ErrorCode> {
    if (!encryptionInfo) {
      Logger.warn(TAG, 'ProcessDataKeyChangedByReconnect: encryptionInfo is null');
      return Promise.reject(ErrorCode.INPUT_PARAMETER_INVALID);
    }

    const dataKeyStatus = encryptionInfo.keyStatus;
    Logger.info(
      TAG,
      `ProcessDataKeyChangedByReconnect: process reconnect with dataKey changed,' +
            ' keyStatus: ${dataKeyStatus}.`
    );
    const isDataKeyChanged =
      dataKeyStatus === EncryptionKeyStatus.INTERRUPT ||
      (dataKeyStatus === EncryptionKeyStatus.NORMAL &&
        this.userDataKeyInfo.dataKeyVersion < encryptionInfo.keyVersion);
    if (!isDataKeyChanged) {
      return Promise.resolve(ErrorCode.OK);
    }
    await this.refreshDataKeyCache(encryptionInfo);
    Logger.info(TAG, 'processDataKeyChangedByReconnect success');
    return Promise.resolve(ErrorCode.OK);
  }

  private async refreshDataKeyCache(outputInfo: EncryptInfo): Promise<void> {
    this.clearOldDataKeyInfo();
    if (
      !outputInfo.dataKeyCipherText ||
      outputInfo.dataKeyCipherText.byteLength !== DATA_KEY_CIPHER_SIZE
    ) {
      Logger.warn(
        TAG,
        `refreshDataKeyCache: cloud saved dataKeyCipherText is invalid,
             dataKeyCipherText length: ${outputInfo.dataKeyCipherText?.length}`
      );
      return Promise.reject(ErrorCode.DATA_ENCRYPTION_KEY_INVALID);
    }
    this.saveDataKeyCipher(outputInfo, this.userDataKeyInfo);
    const dataKeyInfos = await this.decryptQueryCipherText(this.userDataKeyInfo);
    const dataKeyPlainText = dataKeyInfos[0];
    const oldDataKeyPlainText = dataKeyInfos[1];
    const oldKeyLen = this.saveUserDataKey(
      dataKeyPlainText,
      oldDataKeyPlainText,
      this.userDataKeyInfo
    );
    await this.entireEncryption.setKeys(
      this.userDataKeyInfo.userId,
      dataKeyPlainText,
      KEY_SIZE,
      oldDataKeyPlainText,
      oldKeyLen,
      this.userDataKeyInfo.dataKeyVersion
    );
  }

  private async decryptQueryCipherText(
    dataKeyInfo: UserDataKeyInfo
  ): Promise<[Uint8Array, Uint8Array]> {
    const decryptProjectInfo: [Uint8Array, Uint8Array] = [
      new Uint8Array(DATA_KEY_TEXT_SIZE),
      new Uint8Array(DATA_KEY_TEXT_SIZE)
    ];
    const cipherText = Array.from(dataKeyInfo.userDataKeyCipher.cipherText).concat(
      Array.from(dataKeyInfo.userDataKeyCipher.tag)
    );
    const iv = dataKeyInfo.userDataKeyCipher.iv;
    try {
      decryptProjectInfo[0] = await this.entireEncryption.aesGcm256Decrypt(
        new Uint8Array(cipherText),
        dataKeyInfo.userRootKey,
        iv
      );
    } catch (e) {
      Logger.error(TAG, 'decryptQueryCipherText:decrypt dataKeyCipher failed.');
      return Promise.reject(ErrorCode.DECRYPT_FAILED);
    }
    if (dataKeyInfo.userOldDataKeyCipherLen > 0) {
      const oldCipherText = Array.from(dataKeyInfo.userOldDataKeyCipher.cipherText).concat(
        Array.from(dataKeyInfo.userOldDataKeyCipher.tag)
      );
      const oldIv = dataKeyInfo.userOldDataKeyCipher.iv;
      try {
        decryptProjectInfo[1] = await this.entireEncryption.aesGcm256Decrypt(
          new Uint8Array(oldCipherText),
          dataKeyInfo.userRootKey,
          oldIv
        );
      } catch (e) {
        Logger.error(TAG, 'QueryDataKeyCipher:decrypt oldDataKeyCipher failed.');
        return Promise.reject(ErrorCode.DECRYPT_FAILED);
      }
    }
    return Promise.resolve(decryptProjectInfo);
  }

  private saveDataKeyCipher(outputInfo: EncryptInfo, dataKeyInfo: UserDataKeyInfo) {
    // slice ByteArray
    const dataKeyCipherText = outputInfo.dataKeyCipherText as Uint8Array;
    const iv = dataKeyCipherText.slice(0, IV_SIZE);
    const tag = dataKeyCipherText.slice(IV_SIZE, IV_SIZE + TAG_SIZE);
    const cipherText = dataKeyCipherText.slice(IV_SIZE + TAG_SIZE, dataKeyCipherText.length);
    dataKeyInfo.userDataKeyCipher = {
      cipherText,
      tag,
      iv
    };

    dataKeyInfo.userDataKeyCipherLen = DATA_KEY_CIPHER_SIZE;
    dataKeyInfo.dataKeyVersion = outputInfo.keyVersion;
    dataKeyInfo.dataKeyStatus = outputInfo.keyStatus;
    if (
      outputInfo.oldDataKeyCipherText &&
      outputInfo.oldDataKeyCipherText.length === DATA_KEY_CIPHER_SIZE
    ) {
      const oldDataKeyCipherText = outputInfo.oldDataKeyCipherText;
      const oldIv = oldDataKeyCipherText.slice(0, IV_SIZE);
      const oldTag = oldDataKeyCipherText.slice(IV_SIZE, IV_SIZE + TAG_SIZE);
      const oldCipherText = oldDataKeyCipherText.slice(
        IV_SIZE + TAG_SIZE,
        oldDataKeyCipherText.length
      );
      dataKeyInfo.userOldDataKeyCipher = {
        cipherText: oldCipherText,
        tag: oldTag,
        iv: oldIv
      };
      dataKeyInfo.userOldDataKeyCipherLen = DATA_KEY_CIPHER_SIZE;
    }
  }

  private saveUserDataKey(
    dataKeyPlainText: Uint8Array,
    oldDataKeyPlainText: Uint8Array,
    dataKeyInfo: UserDataKeyInfo
  ) {
    const encodeDataKey = Utils.uint8ArrayToWordArray(dataKeyPlainText);
    dataKeyInfo.userDataKey = Utils.stringToUint8Array(this.encodeDataKey(encodeDataKey));
    dataKeyInfo.userDataKeyLen = ENCODE_KEY_SIZE;
    let oldKeyLen = 0;
    if (dataKeyInfo.userOldDataKeyCipherLen > 0) {
      const oldEncodeDataKey = Utils.uint8ArrayToWordArray(oldDataKeyPlainText);
      dataKeyInfo.userOldDataKey = Utils.stringToUint8Array(this.encodeDataKey(oldEncodeDataKey));
      dataKeyInfo.userDataKeyLen = ENCODE_KEY_SIZE;
      oldKeyLen = KEY_SIZE;
    }
    return oldKeyLen;
  }

  private async getSaltFromCloud(): Promise<EncryptResult> {
    const encryptResult = await this.cloudStorage.querySaltValue();
    if (encryptResult.resultCode !== ErrorCode.OK) {
      Logger.warn(TAG, 'GetSaltFromCloud: cloud has not saved this user`s salt.');
      return encryptResult;
    }
    if (
      !encryptResult.encryptInfo[0] ||
      !encryptResult.encryptInfo[0].firstSaltValue ||
      !encryptResult.encryptInfo[0].secondSaltValue
    ) {
      Logger.warn(TAG, 'GetSaltFromCloud: cloud saved salt value is null.');
      return new EncryptResult(ErrorCode.ENCRYPTION_SALT_EMPTY, []);
    }
    if (
      encryptResult.encryptInfo[0].firstSaltValue?.length !== SALT_SIZE ||
      encryptResult.encryptInfo[0].secondSaltValue?.length !== SALT_SIZE
    ) {
      Logger.warn(
        TAG,
        `GetSaltFromCloud: cloud saved salt length is not effective length,\
             firstSalt length:${encryptResult.encryptInfo[0].firstSaltValue?.length},\
              secondSalt length:${encryptResult.encryptInfo[0].secondSaltValue?.length}`
      );
      return new EncryptResult(ErrorCode.INTERNAL_ERROR, []);
    }
    return encryptResult;
  }

  private async InsertEncryptionInfoToCloud(dataKeyInfo: UserDataKeyInfo): Promise<void> {
    const encryptionInfo = new EncryptInfo();
    encryptionInfo.firstSaltValue = dataKeyInfo.rootKeySalt;
    encryptionInfo.secondSaltValue = dataKeyInfo.rootKeyTokenSalt;
    encryptionInfo.rootKeyToken = dataKeyInfo.userRootKeyToken;
    const cipherTextStr = Array.from(dataKeyInfo.userDataKeyCipher.iv)
      .concat(Array.from(dataKeyInfo.userDataKeyCipher.tag))
      .concat(Array.from(dataKeyInfo.userDataKeyCipher.cipherText));
    encryptionInfo.dataKeyCipherText = new Uint8Array(cipherTextStr);
    const result: EncryptResult = await this.cloudStorage.insertEncryptedInfo(encryptionInfo);
    if (result.resultCode !== ErrorCode.OK) {
      Logger.warn(TAG, `InsertEncryptionInfoToCloud: insert encrypt info failed.`);
      return Promise.reject(result.resultCode);
    }
  }

  private async queryDataKeyCipherFromCloud(dataKeyInfo: UserDataKeyInfo): Promise<void> {
    const inputInfo = new EncryptInfo();
    inputInfo.rootKeyToken = dataKeyInfo.userRootKeyToken;
    const responseInfo = await this.cloudStorage.queryDataKeyCipherText(inputInfo);
    if (responseInfo.resultCode !== ErrorCode.OK) {
      Logger.warn(TAG, 'QueryDataKeyCipherFromCloud: query dataKeyCipher failed.');
      return Promise.reject(responseInfo.resultCode);
    }

    const outputInfo = responseInfo.encryptInfo[0];
    if (
      !outputInfo.dataKeyCipherText ||
      outputInfo.dataKeyCipherText.length !== DATA_KEY_CIPHER_SIZE
    ) {
      Logger.warn(
        TAG,
        `queryDataKeyCipherFromCloud: cloud saved dataKeyCipherText is invalid,
             dataKeyCipherText length: ${outputInfo.dataKeyCipherText?.length}`
      );
      return Promise.reject(ErrorCode.INTERNAL_ERROR);
    }
    this.saveDataKeyCipher(outputInfo, dataKeyInfo);
  }

  private async updateEncryptionInfoToCloud(
    oldRootKeyToken: Uint8Array,
    dataKeyInfo: UserDataKeyInfo
  ): Promise<void> {
    const inputOldInfo = new EncryptInfo();
    inputOldInfo.rootKeyToken = oldRootKeyToken;
    const cipherTextStr = Array.from(dataKeyInfo.userDataKeyCipher.iv)
      .concat(Array.from(dataKeyInfo.userDataKeyCipher.tag))
      .concat(Array.from(dataKeyInfo.userDataKeyCipher.cipherText));
    const inputNewInfo = new EncryptInfo();
    inputNewInfo.firstSaltValue = dataKeyInfo.rootKeySalt;
    inputNewInfo.secondSaltValue = dataKeyInfo.rootKeyTokenSalt;
    inputNewInfo.rootKeyToken = dataKeyInfo.userRootKeyToken;
    inputNewInfo.dataKeyCipherText = new Uint8Array(cipherTextStr);
    if (dataKeyInfo.userOldDataKeyCipherLen > 0) {
      const oldCipherTextStr = Array.from(dataKeyInfo.userOldDataKeyCipher.iv)
        .concat(Array.from(dataKeyInfo.userOldDataKeyCipher.tag))
        .concat(Array.from(dataKeyInfo.userOldDataKeyCipher.cipherText));
      inputNewInfo.oldDataKeyCipherText = new Uint8Array(oldCipherTextStr);
    }
    const result: EncryptResult = await this.cloudStorage.updateEncryptedInfo(
      inputOldInfo,
      inputNewInfo
    );
    if (result.resultCode !== ErrorCode.OK) {
      Logger.warn(TAG, `updateEncryptionInfoToCloud: update encrypt info failed.`);
      return Promise.reject(result.resultCode);
    }
  }

  private async getUserId(): Promise<string | undefined> {
    const user = await ConfigWrapper.getConfigInstance().getCurrentUser();
    const userId = user?.getUid();
    if (Utils.isNullOrUndefined(user) || Utils.isNullOrUndefined(userId)) {
      Logger.error(TAG, `getUserId: this user is not authenticated.`);
      return Promise.reject(ErrorCode.LOCAL_PERMISSION_DENIED);
    }
    return userId;
  }

  private async checkDataKeyCache(): Promise<void> {
    const userId = await this.getUserId();
    if (
      this.userDataKeyInfo.userRootKeyLen !== KEY_SIZE ||
      this.userDataKeyInfo.userRootKeyTokenLen !== KEY_SIZE
    ) {
      Logger.warn(TAG, 'checkDataKeyCache: user key is invalid, please verify user key first.');
      return Promise.reject(ErrorCode.DATA_ENCRYPTION_KEY_INVALID);
    }
    if (userId !== this.userDataKeyInfo.userId) {
      Logger.warn(
        TAG,
        'checkDataKeyCache: this user is not the current user, please verify user key first.'
      );
      return Promise.reject(ErrorCode.LOCAL_PERMISSION_DENIED);
    }
  }

  private checkUserKeyFormat(userKey: string, needStrongCheck: boolean) {
    const isValid = needStrongCheck
      ? HIGH_REGEX_OF_USER_KEY.test(userKey)
      : LOW_REGEX_OF_USER_KEY.test(userKey);
    if (!isValid) {
      Logger.error(TAG, 'checkUserKeyFormat: user key is invalid.');
      throw ExceptionUtil.build(ErrorCode.USER_KEY_INVALID);
    }
  }

  // @ts-ignore
  private encodeDataKey(key: CryptoJS.lib.WordArray): string {
    return Utils.encode(key);
  }

  public generateRandom(num: number): Uint8Array {
    return this.entireEncryption.generateRandom(num);
  }

  public clearDataKeyInfo(): void {
    Logger.info(TAG, `clearDataKeyInfo: clear dataKey.`);
    this.userDataKeyInfo.userId = ``;
    this.userDataKeyInfo.userRootKeyLen = 0;
    this.userDataKeyInfo.userRootKeyTokenLen = 0;
    this.userDataKeyInfo.userRootKey = new Uint8Array(0);
    this.userDataKeyInfo.userRootKeyToken = new Uint8Array(0);
    this.clearOldDataKeyInfo();
  }

  private clearOldDataKeyInfo(): void {
    this.userDataKeyInfo.dataKeyVersion = 0;
    this.userDataKeyInfo.dataKeyStatus = 0;
    this.userDataKeyInfo.userDataKeyLen = 0;
    this.userDataKeyInfo.userDataKeyCipherLen = 0;
    this.userDataKeyInfo.userOldDataKeyLen = 0;
    this.userDataKeyInfo.userOldDataKeyCipherLen = 0;
    this.userDataKeyInfo.userDataKey = new Uint8Array(0);
    this.userDataKeyInfo.userDataKeyCipher = {
      iv: new Uint8Array(0),
      tag: new Uint8Array(0),
      cipherText: new Uint8Array(0)
    };
    this.userDataKeyInfo.userOldDataKey = new Uint8Array(0);
    this.userDataKeyInfo.userOldDataKeyCipher = {
      iv: new Uint8Array(0),
      tag: new Uint8Array(0),
      cipherText: new Uint8Array(0)
    };
  }
}

class UserDataKeyInfo {
  userId: string;
  userRootKey: Uint8Array;
  userRootKeyToken: Uint8Array;
  userDataKey: Uint8Array;
  userDataKeyCipher: CipherTextInfo;
  userOldDataKey: Uint8Array;
  userOldDataKeyCipher: CipherTextInfo;
  userRootKeyLen: number;
  userRootKeyTokenLen: number;
  userDataKeyLen: number;
  userDataKeyCipherLen: number;
  dataKeyVersion: number;
  dataKeyStatus: number;
  userOldDataKeyLen: number;
  userOldDataKeyCipherLen: number;
  rootKeySalt: Uint8Array;
  rootKeyTokenSalt: Uint8Array;

  constructor() {
    this.userId = '';
    this.userRootKey = new Uint8Array(0);
    this.userRootKeyToken = new Uint8Array(0);
    this.userDataKey = new Uint8Array(0);
    this.userDataKeyCipher = {
      iv: new Uint8Array(0),
      tag: new Uint8Array(0),
      cipherText: new Uint8Array(0)
    };
    this.userOldDataKey = new Uint8Array(0);
    this.userOldDataKeyCipher = {
      iv: new Uint8Array(0),
      tag: new Uint8Array(0),
      cipherText: new Uint8Array(0)
    };
    this.userRootKeyLen = 0;
    this.userRootKeyTokenLen = 0;
    this.userDataKeyLen = 0;
    this.userDataKeyCipherLen = 0;
    this.dataKeyVersion = 0;
    this.dataKeyStatus = 0;
    this.userOldDataKeyLen = 0;
    this.userOldDataKeyCipherLen = 0;
    this.rootKeySalt = new Uint8Array(0);
    this.rootKeyTokenSalt = new Uint8Array(0);
  }

  copy(dataKeyInfo: UserDataKeyInfo) {
    this.userId = dataKeyInfo.userId;
    this.userRootKey = new Uint8Array(dataKeyInfo.userRootKey);
    this.userRootKeyToken = new Uint8Array(dataKeyInfo.userRootKeyToken);
    this.userDataKey = new Uint8Array(dataKeyInfo.userDataKey);
    this.userDataKeyCipher = {
      iv: new Uint8Array(dataKeyInfo.userDataKeyCipher.iv),
      tag: new Uint8Array(dataKeyInfo.userDataKeyCipher.tag),
      cipherText: new Uint8Array(dataKeyInfo.userDataKeyCipher.cipherText)
    };
    this.userOldDataKey = new Uint8Array(dataKeyInfo.userOldDataKey);
    this.userOldDataKeyCipher = {
      iv: new Uint8Array(dataKeyInfo.userOldDataKeyCipher.iv),
      tag: new Uint8Array(dataKeyInfo.userOldDataKeyCipher.tag),
      cipherText: new Uint8Array(dataKeyInfo.userOldDataKeyCipher.cipherText)
    };
    this.userRootKeyLen = dataKeyInfo.userRootKeyLen;
    this.userRootKeyTokenLen = dataKeyInfo.userRootKeyTokenLen;
    this.userDataKeyLen = dataKeyInfo.userDataKeyLen;
    this.userDataKeyCipherLen = dataKeyInfo.userDataKeyCipherLen;
    this.dataKeyVersion = dataKeyInfo.dataKeyVersion;
    this.dataKeyStatus = dataKeyInfo.dataKeyStatus;
    this.userOldDataKeyLen = dataKeyInfo.userOldDataKeyLen;
    this.userOldDataKeyCipherLen = dataKeyInfo.userOldDataKeyCipherLen;
    this.rootKeySalt = new Uint8Array(dataKeyInfo.rootKeySalt);
    this.rootKeyTokenSalt = new Uint8Array(dataKeyInfo.rootKeyTokenSalt);
  }
}
