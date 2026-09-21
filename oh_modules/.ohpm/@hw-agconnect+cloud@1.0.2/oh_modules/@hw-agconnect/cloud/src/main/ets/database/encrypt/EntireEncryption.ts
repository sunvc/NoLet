/**
 * Copyright (c) Huawei Technologies Co., Ltd. 2020-2020. All rights reserved.
 */

import { Logger } from '@hw-agconnect/hmcore';
import { OpenHarmonyEncrypt } from './compatible/OpenHarmonyEncrypt';
import { IV_SIZE, TAG_SIZE } from './SecretKeyManager';
import { Utils } from '../utils/Utils';
import { FieldType, FieldTypeNamespace } from '../utils/SchemaNamespace';
import { OpeGenerator } from './ope/OpeGenerator';
import { FieldInfo } from '../query/FieldInfo';
import { ObjectWrapper } from '../sync/ObjectWrapper';
import { OpeDataType } from './ope/Utils/OpeDataType';
// @ts-ignore
import Long from 'long';
import { ExceptionUtil } from '../utils/ExceptionUtil';
import { ErrorCode } from '../utils/ErrorCode';
import { BaseEncrypt } from './compatible/BaseEncrypt';
import { NaturalBaseRef } from '../base/NaturalBaseRef';
import { ConfigWrapper } from '../config/ConfigWrapper';
import { CloudDBCryptoJS } from './crypto/CloudDBCryptoJS';
import { CertificateService } from '../security/CertificateService';
import { DatabaseZoneQuery } from '../DatabaseZoneQuery';

const CryptoJS = CloudDBCryptoJS.getCryptoJS();

// IV key salt format, used to derive the IV key from dataKey
const IV_KEY_SALT_FORMAT = ` generate IV key with encryption algorithm AES_256_GCM_HMAC_SHA256`;
// encryption key salt format, used to derive the encryption key from dataKey
const ENCRYPTION_KEY_SALT_FORMAT =
  ` generate encryption key with encryption algorithm ` + `AES_256_GCM_HMAC_SHA256`;
// ope key salt format, used to derive the ope key from dataKey
const OPE_KEY_SALT_FORMAT =
  ` generate Order-preserving key with encryption algorithm ` + `AES_256_GCM_HMAC_SHA256`;
const MAX_CHAR_LENGTH = 800;
const OPE_STRING = '#ope';
const TAG = 'EntireEncryption';

export class EntireEncryption {
  private static encryptor: BaseEncrypt = new OpenHarmonyEncrypt();
  private userKeysInfo: UserKeysInfo;
  private encryptInstance: BaseEncrypt;
  private readonly naturalBaseRef: NaturalBaseRef;

  public constructor(naturalBaseRef: NaturalBaseRef) {
    this.encryptInstance = EntireEncryption.encryptor;
    this.userKeysInfo = new UserKeysInfo();
    this.naturalBaseRef = naturalBaseRef;
  }

  public async aesGcm256Encrypt(
    plainText: Uint8Array,
    key: Uint8Array,
    iv: Uint8Array
  ): Promise<Uint8Array> {
    return await this.encryptInstance.encrypt(plainText, key, iv);
  }

  public async aesGcm256Decrypt(
    cipherText: Uint8Array,
    key: Uint8Array,
    iv: Uint8Array
  ): Promise<Uint8Array> {
    return await this.encryptInstance.decrypt(cipherText, key, iv);
  }

  public generateRandom(num: number): Uint8Array {
    return this.encryptInstance.generateRandom(num);
  }

  public async setKeys(
    userId: string,
    dataKey: Uint8Array,
    keyLen: number,
    oldDataKey: Uint8Array,
    oldKeyLen: number,
    dataKeyVersion: number
  ): Promise<void> {
    if (
      Utils.isNullOrUndefined(dataKey) ||
      Utils.isNullOrUndefined(oldDataKey) ||
      keyLen <= 0 ||
      oldKeyLen < 0 ||
      dataKeyVersion <= 0
    ) {
      Logger.error(TAG, `setKeys: input dataKey or oldDataKey is invalid.`);
      return Promise.reject(ErrorCode.DATA_ENCRYPTION_KEY_INVALID);
    }
    Logger.info(TAG, `setKeys: set iv key and encrypted key.`);
    // when switching user, need to clean last user key info.
    if (!Utils.isStringEmpty(this.userKeysInfo.userId)) {
      this.clearUserKeysInfo();
    }

    try {
      this.generateKeys(dataKey, oldDataKey, oldKeyLen);
    } catch (ex) {
      Logger.error(TAG, `setKeys: set keys failed.`);
      this.clearUserKeysInfo();
      return Promise.reject(ex.getCode());
    }
    this.userKeysInfo.userId = userId;
    this.userKeysInfo.dataKeyVersion = dataKeyVersion;
  }

  public async conditionEntireEncryptedField(
    schemaName: string,
    fieldName: string,
    fieldType: FieldType,
    value: any
  ): Promise<any> {
    this.naturalBaseRef.getEntireEncryptInterval().setIntervalCleanKey(true);
    const plaintext = this.getPlainText(fieldType, value);
    return await this.getOpeFieldDataValue(schemaName, fieldName, fieldType, plaintext);
  }

  public async encryptEntireEncryptedFields(objectItems: any[]): Promise<any[]> {
    Logger.debug(TAG, `encryptEntireEncryptedFields: objectItems size: ${objectItems.length}`);
    const encryptObjectList: any[] = [];
    const copyObjectList = Utils.deepCopy(objectItems);
    for (const objectItem of copyObjectList) {
      const schemaName = Utils.getClassName(objectItem);
      await this.isValidEncryptionOperation(schemaName);
      encryptObjectList.push(await this.handleEntireEncryptedField(schemaName, objectItem));
    }
    Logger.debug(TAG, `encryptEntireEncryptedFields done`);
    return Promise.resolve(encryptObjectList);
  }

  private async handleEntireEncryptedField(schemaName: string, objectItem: any): Promise<any> {
    const schema = this.naturalBaseRef.getDefaultNaturalStore().getAppSchema().get(schemaName);
    const encryptedFields = schema!.getEncryptFieldList();
    let encryptObject = objectItem;
    for (const value of encryptedFields) {
      this.naturalBaseRef.getEntireEncryptInterval().setIntervalCleanKey(true);
      encryptObject = await this.encryptEntireEncryptedField(
        schemaName,
        value.fieldName,
        value.fieldType,
        objectItem
      );
    }
    return Promise.resolve(encryptObject);
  }

  private async encryptEntireEncryptedField(
    schemaName: string,
    fieldName: string,
    fieldType: FieldType,
    object: any
  ): Promise<any> {
    const inputValue = object[fieldName];
    if (Utils.isNullOrUndefined(inputValue)) {
      return object;
    }

    await this.checkUserId();
    const plaintext = this.getPlainText(fieldType, inputValue);
    object[fieldName] = await this.encryptFieldData(schemaName, fieldName, plaintext);
    const opeValue = await this.getOpeFieldDataValue(schemaName, fieldName, fieldType, plaintext);
    const opeFieldName = fieldName.indexOf(OPE_STRING) !== -1 ? fieldName : fieldName + OPE_STRING;
    object[opeFieldName] = opeValue;
    return Promise.resolve(object);
  }

  private getPlainText(fieldType: FieldType, inputValue: any) {
    let plaintext = '';
    const fieldTypeStr = FieldTypeNamespace.toString(fieldType);
    switch (fieldType) {
      case FieldType.Boolean:
        plaintext = inputValue === true ? '1' : '0';
        break;
      case FieldType.Integer:
      case FieldType.Short:
      case FieldType.Float:
      case FieldType.Double:
      case FieldType.Byte:
      case FieldType.Long:
      case FieldType.IntAutoIncrement:
      case FieldType.LongAutoIncrement:
        plaintext = inputValue.toString();
        break;
      case FieldType.Date:
        plaintext = inputValue.getTime().toString();
        break;
      case FieldType.String:
        plaintext = inputValue;
        break;
      default:
        Logger.error(TAG, `getPlainText: inputValue fieldType:${fieldTypeStr} is error.`);
        throw ExceptionUtil.build(ErrorCode.INPUT_PARAMETER_INVALID);
    }
    if (plaintext.length > MAX_CHAR_LENGTH) {
      Logger.error(TAG, `Plaintext length cannot be greater than ${MAX_CHAR_LENGTH}.`);
      throw ExceptionUtil.build(ErrorCode.INPUT_PARAMETER_INVALID);
    }
    return plaintext;
  }

  private async encryptFieldData(
    schemaName: string,
    fieldName: string,
    plaintext: string
  ): Promise<Uint8Array> {
    const tableFieldName = '' + schemaName + ':' + fieldName;
    const gcmIv = this.calculateGcmIv(tableFieldName, Utils.stringToUint8Array(plaintext));
    let encryptedKey = this.userKeysInfo.encryptedKeyMap.get(tableFieldName);
    if (!encryptedKey) {
      Logger.warn(TAG, 'encryptFieldData: this field has not encryptKey.');
      this.generateEncryptedKey(tableFieldName, this.userKeysInfo.dataKeyPlaintext);
      encryptedKey = this.userKeysInfo.encryptedKeyMap.get(tableFieldName);
      if (!encryptedKey) {
        Logger.error(TAG, 'encryptFieldData: not found regenerate field encryptKey.');
        throw ExceptionUtil.build(ErrorCode.INTERNAL_ERROR);
      }
    }
    const encryptArray = await this.aesGcm256Encrypt(
      Utils.stringToUint8Array(plaintext),
      encryptedKey,
      gcmIv
    );
    if (!encryptArray) {
      Logger.error(TAG, 'encryptFieldData: encrypt failed.');
      throw ExceptionUtil.build(ErrorCode.ENCRYPT_FAILED);
    }
    // slice
    const cipherTextArray = encryptArray.slice(0, encryptArray.length - TAG_SIZE);
    const tagArray = encryptArray.slice(encryptArray.length - TAG_SIZE, encryptArray.length);
    const cipherStr = Array.from(gcmIv)
      .concat(Array.from(tagArray))
      .concat(Array.from(cipherTextArray));
    return Promise.resolve(new Uint8Array(cipherStr));
  }

  private calculateGcmIv(tableName: string, plainText: Uint8Array) {
    let ivKey = this.userKeysInfo.ivKeyMap.get(tableName);
    if (!ivKey) {
      if (!this.userKeysInfo.dataKeyPlaintext) {
        Logger.error(TAG, 'calculateGcmIv: this field has not encryptedKey.');
        throw ExceptionUtil.build(ErrorCode.INTERNAL_ERROR);
      }
      this.generateIvKey(tableName, this.userKeysInfo.dataKeyPlaintext);
      ivKey = this.userKeysInfo.ivKeyMap.get(tableName);
      if (!ivKey) {
        Logger.error(TAG, 'calculateGcmIv: GenerateIvKey not found.');
        throw ExceptionUtil.build(ErrorCode.INTERNAL_ERROR);
      }
    }
    const gcmIvWorld = this.calculateHmacSha256(ivKey, Utils.uint8ArrayToString(plainText));
    const gcmIvArray = Utils.wordArrayToUint8Array(gcmIvWorld);
    return gcmIvArray.slice(0, IV_SIZE);
  }

  private async getOpeFieldDataValue(
    schemaName: string,
    fieldName: string,
    fieldType: FieldType,
    plaintext: string
  ): Promise<string> {
    const plaintextLen = plaintext.length > 0 ? plaintext.length : 1;
    const tableFieldName = '' + schemaName + ':' + fieldName;
    let opeKey = this.userKeysInfo.opeKeyMap.get(tableFieldName);
    if (!opeKey) {
      Logger.warn(TAG, 'getOpeFieldDataValue: this field has not opeKey.');
      this.generateOpeKey(tableFieldName, this.userKeysInfo.dataKeyPlaintext);
      opeKey = this.userKeysInfo.opeKeyMap.get(tableFieldName);
      if (!opeKey) {
        Logger.error(TAG, 'getOpeFieldDataValue: not found regenerate field opeKey.');
        throw ExceptionUtil.build(ErrorCode.INTERNAL_ERROR);
      }
    }
    const opeDataType = this.convertFieldToOpeDataType(fieldType);
    try {
      const opeValueStr = new OpeGenerator().generateOpeValue(
        plaintext,
        plaintextLen,
        opeDataType,
        opeKey
      );
      return Promise.resolve(opeValueStr);
    } catch (e) {
      Logger.error(TAG, `Encrypt data failed, please check user key validity.for${e}`);
      throw ExceptionUtil.build(ErrorCode.ENCRYPT_FAILED);
    }
  }

  private convertFieldToOpeDataType(fieldType: FieldType) {
    let opeDataType: OpeDataType = OpeDataType.OPE_TYPE_STRING;
    switch (fieldType) {
      case FieldType.Integer: {
        opeDataType = OpeDataType.OPE_TYPE_INT32;
        break;
      }
      case FieldType.Byte: {
        opeDataType = OpeDataType.OPE_TYPE_INT8;
        break;
      }
      case FieldType.Short: {
        opeDataType = OpeDataType.OPE_TYPE_INT16;
        break;
      }
      case FieldType.Long: {
        opeDataType = OpeDataType.OPE_TYPE_INT64;
        break;
      }
      case FieldType.Float: {
        opeDataType = OpeDataType.OPE_TYPE_FLOAT;
        break;
      }
      case FieldType.Double: {
        opeDataType = OpeDataType.OPE_TYPE_DOUBLE;
        break;
      }
      case FieldType.String:
      case FieldType.Text: {
        opeDataType = OpeDataType.OPE_TYPE_STRING;
        break;
      }
      case FieldType.Date: {
        opeDataType = OpeDataType.OPE_TYPE_DATE;
        break;
      }
      case FieldType.Boolean: {
        opeDataType = OpeDataType.OPE_TYPE_BOOL;
        break;
      }
      default: {
        Logger.error(TAG, 'convertFieldToOpeDataType: fieldType is Unknown');
        break;
      }
    }
    return opeDataType;
  }

  public async decryptEntireEncryptedFields<T>(
    query: DatabaseZoneQuery<T>,
    objectItems: Array<any>
  ): Promise<Array<any>> {
    const list: any[] = [];
    const schema = this.naturalBaseRef
      .getDefaultNaturalStore()
      .getAppSchema()
      .get(query.getClassName());
    const encryptedFields = schema!.getEncryptFieldList();
    for (const objectItem of objectItems) {
      const decryptObj = await this.innerDecryptEntireEncryptedFields(
        query,
        encryptedFields,
        objectItem as ObjectWrapper
      );
      list.push(decryptObj);
    }
    return Promise.resolve(list);
  }

  private async innerDecryptEntireEncryptedFields<T>(
    query: DatabaseZoneQuery<T>,
    encryptedFields: FieldInfo[],
    objectItem: ObjectWrapper
  ): Promise<any> {
    objectItem.setObjectTypeName(query.getClazz()!);
    const objectData: any = this.naturalBaseRef
      .getDefaultNaturalStore()
      .getDataModelHelper()
      .deserialize(query.getClazz()!, objectItem.getObject());
    if (!encryptedFields || encryptedFields.length === 0) {
      objectItem.setUserObject(objectData);
      return Promise.resolve(objectData);
    }
    await this.checkUserId();
    for (const encryptedField of encryptedFields) {
      const fieldName = encryptedField.fieldName;
      let cipherText = objectData[fieldName];
      if (!cipherText) {
        continue;
      }
      const encryptKey = this.userKeysInfo.encryptedKeyMap.get(
        query.getClassName() + ':' + fieldName
      );
      if (!encryptKey) {
        Logger.error(TAG, 'innerDecryptEntireEncryptedFields: get encryptKey failed.');
        throw ExceptionUtil.build(ErrorCode.INTERNAL_ERROR);
      }
      this.naturalBaseRef.getEntireEncryptInterval().setIntervalCleanKey(true);
      if (typeof cipherText === 'string') {
        // base64 string
        cipherText = Utils.wordArrayToUint8Array(Utils.decode(cipherText));
      }

      const iv = cipherText.slice(0, IV_SIZE);
      const tag = cipherText.slice(IV_SIZE, IV_SIZE + TAG_SIZE);
      const cipher = cipherText.slice(IV_SIZE + TAG_SIZE, cipherText.length);
      const decipherArray = Array.from(cipher as Uint8Array).concat(Array.from(tag));
      await this.aesGcm256Decrypt(new Uint8Array(decipherArray), encryptKey, iv)
        .then(decryptText => {
          this.decryptFieldData(decryptText, fieldName, encryptedField.fieldType, objectData);
        })
        .catch(() => {
          Logger.error(TAG, 'innerDecryptEntireEncryptedFields: decrypt text failed.');
          throw ExceptionUtil.build(ErrorCode.DECRYPT_FAILED);
        });
    }
    objectItem.setUserObject(objectData);
    return Promise.resolve(objectData);
  }

  private decryptFieldData(
    decryptText: Uint8Array,
    fieldName: string,
    fieldType: FieldType,
    objectData: any
  ) {
    const decryptTextStr = Utils.uint8ArrayToString(decryptText);
    switch (fieldType) {
      case FieldType.Boolean: {
        objectData[fieldName] = decryptTextStr === '1';
        break;
      }
      case FieldType.Byte:
      case FieldType.Short:
      case FieldType.Integer: {
        objectData[fieldName] = parseInt(decryptTextStr, 10);
        break;
      }
      case FieldType.Float:
      case FieldType.Double: {
        objectData[fieldName] = parseFloat(decryptTextStr);
        break;
      }
      case FieldType.String:
      case FieldType.Text: {
        objectData[fieldName] = decryptTextStr;
        break;
      }
      case FieldType.Date: {
        objectData[fieldName] = new Date(parseInt(decryptTextStr, 10));
        break;
      }
      case FieldType.Long: {
        objectData[fieldName] = Long.fromString(decryptTextStr);
        break;
      }
      default: {
        break;
      }
    }
    return objectData;
  }

  public clearUserKeysInfo() {
    Logger.info(TAG, `clearUserKeysInfo: clear userKeys.`);
    this.userKeysInfo.userId = '';
    this.userKeysInfo.dataKeyVersion = 0;
    this.clearUserKey(this.userKeysInfo.ivKeyMap);
    this.clearUserKey(this.userKeysInfo.encryptedKeyMap);
    this.clearUserKey(this.userKeysInfo.oldEncryptedKeyMap);
    this.clearUserKey(this.userKeysInfo.opeKeyMap);
  }

  private clearUserKey(userKeyMap: Map<string, Uint8Array>): void {
    userKeyMap.clear();
  }

  private generateKeys(dataKey: Uint8Array, oldDataKey: Uint8Array, oldKeyLen: number) {
    const currentSchema = this.naturalBaseRef.getDefaultNaturalStore().getAppSchema();
    if (currentSchema.size === 0) {
      Logger.error(TAG, `generateKeys: schemas have not been loaded.`);
      throw ExceptionUtil.build(ErrorCode.INTERNAL_ERROR);
    }
    for (const schema of currentSchema) {
      const encryptFields = schema[1].getEncryptFieldList();
      for (const field of encryptFields) {
        const tableFieldName = schema[0] + ':' + field.fieldName;
        this.generateColumnKeys(tableFieldName, dataKey, oldDataKey, oldKeyLen);
      }
    }
  }

  private generateColumnKeys(
    tableFieldName: string,
    dataKey: Uint8Array,
    oldDataKey: Uint8Array,
    oldKeyLen: number
  ) {
    this.generateEncryptedKey(tableFieldName, dataKey);
    if (oldKeyLen > 0) {
      this.generateOldEncryptedKey(tableFieldName, oldDataKey);
    }
    this.generateIvKey(tableFieldName, dataKey);
    this.generateOpeKey(tableFieldName, dataKey);
  }

  private generateEncryptedKey(tableFieldName: string, dataKey: Uint8Array) {
    if (this.userKeysInfo.encryptedKeyMap.has(tableFieldName)) {
      Logger.info(TAG, `generateEncryptedKey: encryptedKey of the tableFieldName already existed.`);
      return;
    }

    let encryptedKeyMaterial = tableFieldName;
    encryptedKeyMaterial += ENCRYPTION_KEY_SALT_FORMAT;
    const result = this.calculateHmacSha256(dataKey, encryptedKeyMaterial);
    this.userKeysInfo.encryptedKeyMap.set(tableFieldName, Utils.wordArrayToUint8Array(result));
  }

  private generateOldEncryptedKey(tableFieldName: string, oldDataKey: Uint8Array) {
    if (this.userKeysInfo.oldEncryptedKeyMap.has(tableFieldName)) {
      Logger.info(
        TAG,
        `generateOldEncryptedKey: oldEncryptedKey of the tableFieldName already existed.`
      );
      return;
    }

    const encryptedKeyMaterial = tableFieldName + ENCRYPTION_KEY_SALT_FORMAT;
    const result = this.calculateHmacSha256(oldDataKey, encryptedKeyMaterial);
    this.userKeysInfo.oldEncryptedKeyMap.set(tableFieldName, Utils.wordArrayToUint8Array(result));
  }

  private generateIvKey(tableFieldName: string, dataKey: Uint8Array) {
    if (this.userKeysInfo.ivKeyMap.has(tableFieldName)) {
      Logger.info(TAG, `generateIvKey: ivKey of the tableFieldName already existed.`);
      return;
    }

    const encryptedKeyMaterial = tableFieldName + IV_KEY_SALT_FORMAT;
    const result = this.calculateHmacSha256(dataKey, encryptedKeyMaterial);
    this.userKeysInfo.ivKeyMap.set(tableFieldName, Utils.wordArrayToUint8Array(result));
  }

  private generateOpeKey(tableFieldName: string, dataKey: Uint8Array) {
    if (this.userKeysInfo.opeKeyMap.has(tableFieldName)) {
      Logger.info(TAG, `generateOpeKey: opeKey of the tableFieldName already existed.`);
      return;
    }

    const encryptedKeyMaterial = tableFieldName + OPE_KEY_SALT_FORMAT;
    const result = this.calculateHmacSha256(dataKey, encryptedKeyMaterial);
    this.userKeysInfo.opeKeyMap.set(tableFieldName, result);
  }

  // @ts-ignore
  private calculateHmacSha256(key: Uint8Array, data: string): CryptoJS.lib.WordArray {
    const hmacKey = Utils.uint8ArrayToWordArray(key);
    const hmacData = Utils.uint8ArrayToWordArray(Utils.stringToUint8Array(data));
    const hmac = CryptoJS.HmacSHA256(hmacData, hmacKey);
    if (!hmac) {
      Logger.error(TAG, `calculateHmacSha256: calculate hmac failed.`);
      throw ExceptionUtil.build(ErrorCode.INTERNAL_ERROR);
    }
    return hmac;
  }

  public async isValidEncryptionOperation(schemaName: string): Promise<void> {
    try {
      const schema = this.naturalBaseRef.getDefaultNaturalStore().getAppSchema().get(schemaName);
      if (!schema?.isEncryptTable()) {
        return;
      }
      CertificateService.checkSupportEncryption();
      await this.checkUserId();
    } catch (error) {
      return Promise.reject(Utils.isErrorObject(error) ? error : ExceptionUtil.build(error));
    }
  }

  private async checkUserId(): Promise<void> {
    const user = await ConfigWrapper.getConfigInstance().getCurrentUser();
    const userId = user?.getUid();
    if (!userId || userId.length === 0) {
      Logger.error(TAG, 'checkUserId: this user is not authenticated.');
      return Promise.reject(ErrorCode.LOCAL_PERMISSION_DENIED);
    }
    if (this.userKeysInfo.dataKeyVersion === 0) {
      Logger.error(TAG, 'checkUserId: data key version is invalid.');
      return Promise.reject(ErrorCode.DATA_ENCRYPTION_KEY_INVALID);
    }
    if (userId !== this.userKeysInfo.userId) {
      Logger.error(
        TAG,
        'checkUserId: this user is not the current user, please verify user key first.'
      );
      return Promise.reject(ErrorCode.LOCAL_PERMISSION_DENIED);
    }
  }

  public GetEncryptVersion() {
    return this.userKeysInfo.dataKeyVersion;
  }
}

class UserKeysInfo {
  userId: string;
  dataKeyVersion: number;
  ivKeyMap: Map<string, Uint8Array> = new Map();
  encryptedKeyMap: Map<string, Uint8Array> = new Map();
  oldEncryptedKeyMap: Map<string, Uint8Array> = new Map();
  opeKeyMap: Map<string, any> = new Map();
  dataKeyPlaintext: Uint8Array;
  oldDataKeyPlaintext: Uint8Array;
  dataKeyPlaintextLen: number;
  oldDataKeyPlaintextLen: number;

  constructor() {
    this.userId = '';
    this.dataKeyVersion = 0;
    this.dataKeyPlaintext = new Uint8Array();
    this.oldDataKeyPlaintext = new Uint8Array();
    this.dataKeyPlaintextLen = 0;
    this.oldDataKeyPlaintextLen = 0;
  }
}
