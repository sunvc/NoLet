import * as $protobuf from 'protobufjs';
import Long from 'long';

export namespace naturalcloudsyncv2 {
  interface ISchema {
    n?: string | null;
    fs?: naturalcloudsyncv2.ISchemaField[] | null;
  }

  class Schema implements ISchema {
    constructor(properties?: naturalcloudsyncv2.ISchema);
    public n: string;
    public fs: naturalcloudsyncv2.ISchemaField[];
    public static create(properties?: naturalcloudsyncv2.ISchema): naturalcloudsyncv2.Schema;
    public static encode(
      message: naturalcloudsyncv2.ISchema,
      writer?: $protobuf.Writer
    ): $protobuf.Writer;
    public static encodeDelimited(
      message: naturalcloudsyncv2.ISchema,
      writer?: $protobuf.Writer
    ): $protobuf.Writer;
    public static decode(
      reader: $protobuf.Reader | Uint8Array,
      length?: number
    ): naturalcloudsyncv2.Schema;
    public static decodeDelimited(reader: $protobuf.Reader | Uint8Array): naturalcloudsyncv2.Schema;
    public static verify(message: { [k: string]: any }): string | null;
    public static fromObject(object: { [k: string]: any }): naturalcloudsyncv2.Schema;
    public static toObject(
      message: naturalcloudsyncv2.Schema,
      options?: $protobuf.IConversionOptions
    ): { [k: string]: any };
    public toJSON(): { [k: string]: any };
    public static getTypeUrl(typeUrlPrefix?: string): string;
  }

  interface ISchemaField {
    n?: string | null;
    t?: naturalcloudsyncv2.FieldType | null;
    p?: boolean | null;
    e?: boolean | null;
    nn?: boolean | null;
    df?: boolean | null;
    bl?: boolean | null;
    b?: number | null;
    st?: number | null;
    i?: number | null;
    l?: Long | null;
    f?: number | null;
    d?: number | null;
    ba?: Uint8Array | null;
    s?: string | null;
  }

  class SchemaField implements ISchemaField {
    constructor(properties?: naturalcloudsyncv2.ISchemaField);
    public n: string;
    public t: naturalcloudsyncv2.FieldType;
    public p: boolean;
    public e: boolean;
    public nn: boolean;
    public df: boolean;
    public bl?: boolean | null;
    public b?: number | null;
    public st?: number | null;
    public i?: number | null;
    public l?: Long | null;
    public f?: number | null;
    public d?: number | null;
    public ba?: Uint8Array | null;
    public s?: string | null;
    public defaultValue?: 'bl' | 'b' | 'st' | 'i' | 'l' | 'f' | 'd' | 'ba' | 's';
    public static create(
      properties?: naturalcloudsyncv2.ISchemaField
    ): naturalcloudsyncv2.SchemaField;
    public static encode(
      message: naturalcloudsyncv2.ISchemaField,
      writer?: $protobuf.Writer
    ): $protobuf.Writer;
    public static encodeDelimited(
      message: naturalcloudsyncv2.ISchemaField,
      writer?: $protobuf.Writer
    ): $protobuf.Writer;
    public static decode(
      reader: $protobuf.Reader | Uint8Array,
      length?: number
    ): naturalcloudsyncv2.SchemaField;
    public static decodeDelimited(
      reader: $protobuf.Reader | Uint8Array
    ): naturalcloudsyncv2.SchemaField;
    public static verify(message: { [k: string]: any }): string | null;
    public static fromObject(object: { [k: string]: any }): naturalcloudsyncv2.SchemaField;
    public static toObject(
      message: naturalcloudsyncv2.SchemaField,
      options?: $protobuf.IConversionOptions
    ): { [k: string]: any };
    public toJSON(): { [k: string]: any };
    public static getTypeUrl(typeUrlPrefix?: string): string;
  }

  enum FieldType {
    TYPE_DEFAULT = 0,
    TYPE_BOOLEAN = 1,
    TYPE_BYTE = 2,
    TYPE_SHORT = 3,
    TYPE_INT32 = 4,
    TYPE_LONG = 5,
    TYPE_FLOAT = 6,
    TYPE_DOUBLE = 7,
    TYPE_BYTE_ARRAY = 8,
    TYPE_STRING = 9,
    TYPE_DATE = 10,
    TYPE_TEXT = 11,
    TYPE_AUTO_INCREMENT_INT = 12,
    TYPE_AUTO_INCREMENT_LONG = 13
  }

  interface IOperationData {
    os?: naturalcloudsyncv2.IObj[] | null;
    t?: number | null;
    i?: number | null;
  }

  class OperationData implements IOperationData {
    constructor(properties?: naturalcloudsyncv2.IOperationData);
    public os: naturalcloudsyncv2.IObj[];
    public t: number;
    public i: number;
    public static create(
      properties?: naturalcloudsyncv2.IOperationData
    ): naturalcloudsyncv2.OperationData;
    public static encode(
      message: naturalcloudsyncv2.IOperationData,
      writer?: $protobuf.Writer
    ): $protobuf.Writer;
    public static encodeDelimited(
      message: naturalcloudsyncv2.IOperationData,
      writer?: $protobuf.Writer
    ): $protobuf.Writer;
    public static decode(
      reader: $protobuf.Reader | Uint8Array,
      length?: number
    ): naturalcloudsyncv2.OperationData;
    public static decodeDelimited(
      reader: $protobuf.Reader | Uint8Array
    ): naturalcloudsyncv2.OperationData;
    public static verify(message: { [k: string]: any }): string | null;
    public static fromObject(object: { [k: string]: any }): naturalcloudsyncv2.OperationData;
    public static toObject(
      message: naturalcloudsyncv2.OperationData,
      options?: $protobuf.IConversionOptions
    ): { [k: string]: any };
    public toJSON(): { [k: string]: any };
    public static getTypeUrl(typeUrlPrefix?: string): string;
  }

  interface IObj {
    fs?: naturalcloudsyncv2.IField[] | null;
    i?: number | null;
  }

  class Obj implements IObj {
    constructor(properties?: naturalcloudsyncv2.IObj);
    public fs: naturalcloudsyncv2.IField[];
    public i: number;
    public static create(properties?: naturalcloudsyncv2.IObj): naturalcloudsyncv2.Obj;
    public static encode(
      message: naturalcloudsyncv2.IObj,
      writer?: $protobuf.Writer
    ): $protobuf.Writer;
    public static encodeDelimited(
      message: naturalcloudsyncv2.IObj,
      writer?: $protobuf.Writer
    ): $protobuf.Writer;
    public static decode(
      reader: $protobuf.Reader | Uint8Array,
      length?: number
    ): naturalcloudsyncv2.Obj;
    public static decodeDelimited(reader: $protobuf.Reader | Uint8Array): naturalcloudsyncv2.Obj;
    public static verify(message: { [k: string]: any }): string | null;
    public static fromObject(object: { [k: string]: any }): naturalcloudsyncv2.Obj;
    public static toObject(
      message: naturalcloudsyncv2.Obj,
      options?: $protobuf.IConversionOptions
    ): { [k: string]: any };
    public toJSON(): { [k: string]: any };
    public static getTypeUrl(typeUrlPrefix?: string): string;
  }

  interface IField {
    n?: boolean | null;
    bl?: boolean | null;
    b?: number | null;
    st?: number | null;
    i?: number | null;
    l?: Long | null;
    f?: number | null;
    d?: number | null;
    ba?: Uint8Array | null;
    s?: string | null;
  }

  class Field implements IField {
    constructor(properties?: naturalcloudsyncv2.IField);
    public n: boolean;
    public bl?: boolean | null;
    public b?: number | null;
    public st?: number | null;
    public i?: number | null;
    public l?: Long | null;
    public f?: number | null;
    public d?: number | null;
    public ba?: Uint8Array | null;
    public s?: string | null;
    public value?: 'bl' | 'b' | 'st' | 'i' | 'l' | 'f' | 'd' | 'ba' | 's';
    public static create(properties?: naturalcloudsyncv2.IField): naturalcloudsyncv2.Field;
    public static encode(
      message: naturalcloudsyncv2.IField,
      writer?: $protobuf.Writer
    ): $protobuf.Writer;
    public static encodeDelimited(
      message: naturalcloudsyncv2.IField,
      writer?: $protobuf.Writer
    ): $protobuf.Writer;
    public static decode(
      reader: $protobuf.Reader | Uint8Array,
      length?: number
    ): naturalcloudsyncv2.Field;
    public static decodeDelimited(reader: $protobuf.Reader | Uint8Array): naturalcloudsyncv2.Field;
    public static verify(message: { [k: string]: any }): string | null;
    public static fromObject(object: { [k: string]: any }): naturalcloudsyncv2.Field;
    public static toObject(
      message: naturalcloudsyncv2.Field,
      options?: $protobuf.IConversionOptions
    ): { [k: string]: any };
    public toJSON(): { [k: string]: any };
    public static getTypeUrl(typeUrlPrefix?: string): string;
  }

  interface IMessageInfo {
    id?: Long | null;
    type?: number | null;
    subType?: number | null;
    opStore?: naturalcloudsyncv2.IStore | null;
    traceId?: string | null;
  }

  class MessageInfo implements IMessageInfo {
    constructor(properties?: naturalcloudsyncv2.IMessageInfo);
    public id: Long;
    public type: number;
    public subType: number;
    public opStore?: naturalcloudsyncv2.IStore | null;
    public traceId: string;
    public static create(
      properties?: naturalcloudsyncv2.IMessageInfo
    ): naturalcloudsyncv2.MessageInfo;
    public static encode(
      message: naturalcloudsyncv2.IMessageInfo,
      writer?: $protobuf.Writer
    ): $protobuf.Writer;
    public static encodeDelimited(
      message: naturalcloudsyncv2.IMessageInfo,
      writer?: $protobuf.Writer
    ): $protobuf.Writer;
    public static decode(
      reader: $protobuf.Reader | Uint8Array,
      length?: number
    ): naturalcloudsyncv2.MessageInfo;
    public static decodeDelimited(
      reader: $protobuf.Reader | Uint8Array
    ): naturalcloudsyncv2.MessageInfo;
    public static verify(message: { [k: string]: any }): string | null;
    public static fromObject(object: { [k: string]: any }): naturalcloudsyncv2.MessageInfo;
    public static toObject(
      message: naturalcloudsyncv2.MessageInfo,
      options?: $protobuf.IConversionOptions
    ): { [k: string]: any };
    public toJSON(): { [k: string]: any };
    public static getTypeUrl(typeUrlPrefix?: string): string;
  }

  interface IStore {
    storeName?: string | null;
  }

  class Store implements IStore {
    constructor(properties?: naturalcloudsyncv2.IStore);
    public storeName: string;
    public static create(properties?: naturalcloudsyncv2.IStore): naturalcloudsyncv2.Store;
    public static encode(
      message: naturalcloudsyncv2.IStore,
      writer?: $protobuf.Writer
    ): $protobuf.Writer;
    public static encodeDelimited(
      message: naturalcloudsyncv2.IStore,
      writer?: $protobuf.Writer
    ): $protobuf.Writer;
    public static decode(
      reader: $protobuf.Reader | Uint8Array,
      length?: number
    ): naturalcloudsyncv2.Store;
    public static decodeDelimited(reader: $protobuf.Reader | Uint8Array): naturalcloudsyncv2.Store;
    public static verify(message: { [k: string]: any }): string | null;
    public static fromObject(object: { [k: string]: any }): naturalcloudsyncv2.Store;
    public static toObject(
      message: naturalcloudsyncv2.Store,
      options?: $protobuf.IConversionOptions
    ): { [k: string]: any };
    public toJSON(): { [k: string]: any };
    public static getTypeUrl(typeUrlPrefix?: string): string;
  }

  interface IEncryptionInfo {
    keyStatus?: number | null;
    firstSalt?: Uint8Array | null;
    secondSalt?: Uint8Array | null;
    rootToken?: Uint8Array | null;
    cipherText?: Uint8Array | null;
    oldCipherText?: Uint8Array | null;
    keyVer?: number | null;
  }

  class EncryptionInfo implements IEncryptionInfo {
    constructor(properties?: naturalcloudsyncv2.IEncryptionInfo);
    public keyStatus: number;
    public firstSalt: Uint8Array;
    public secondSalt: Uint8Array;
    public rootToken: Uint8Array;
    public cipherText: Uint8Array;
    public oldCipherText: Uint8Array;
    public keyVer: number;
    public static create(
      properties?: naturalcloudsyncv2.IEncryptionInfo
    ): naturalcloudsyncv2.EncryptionInfo;
    public static encode(
      message: naturalcloudsyncv2.IEncryptionInfo,
      writer?: $protobuf.Writer
    ): $protobuf.Writer;
    public static encodeDelimited(
      message: naturalcloudsyncv2.IEncryptionInfo,
      writer?: $protobuf.Writer
    ): $protobuf.Writer;
    public static decode(
      reader: $protobuf.Reader | Uint8Array,
      length?: number
    ): naturalcloudsyncv2.EncryptionInfo;
    public static decodeDelimited(
      reader: $protobuf.Reader | Uint8Array
    ): naturalcloudsyncv2.EncryptionInfo;
    public static verify(message: { [k: string]: any }): string | null;
    public static fromObject(object: { [k: string]: any }): naturalcloudsyncv2.EncryptionInfo;
    public static toObject(
      message: naturalcloudsyncv2.EncryptionInfo,
      options?: $protobuf.IConversionOptions
    ): { [k: string]: any };
    public toJSON(): { [k: string]: any };
    public static getTypeUrl(typeUrlPrefix?: string): string;
  }

  interface ISyncRequestMessage {
    msgInfo?: naturalcloudsyncv2.IMessageInfo | null;
    clientInfo?: naturalcloudsyncv2.IClientInfo | null;
    schemas?: naturalcloudsyncv2.ISchema[] | null;
    opData?: naturalcloudsyncv2.IOperationData[] | null;
    queryReqMsg?: naturalcloudsyncv2.IQueryRequestMessage | null;
    subReqMsg?: naturalcloudsyncv2.ISubscribeRequestMessage[] | null;
    unSubReqMsg?: naturalcloudsyncv2.IUnsubscribeRequestMessage[] | null;
    enReqInfo?: naturalcloudsyncv2.IEncryptionInfo[] | null;
  }

  class SyncRequestMessage implements ISyncRequestMessage {
    constructor(properties?: naturalcloudsyncv2.ISyncRequestMessage);
    public msgInfo?: naturalcloudsyncv2.IMessageInfo | null;
    public clientInfo?: naturalcloudsyncv2.IClientInfo | null;
    public schemas: naturalcloudsyncv2.ISchema[];
    public opData: naturalcloudsyncv2.IOperationData[];
    public queryReqMsg?: naturalcloudsyncv2.IQueryRequestMessage | null;
    public subReqMsg: naturalcloudsyncv2.ISubscribeRequestMessage[];
    public unSubReqMsg: naturalcloudsyncv2.IUnsubscribeRequestMessage[];
    public enReqInfo: naturalcloudsyncv2.IEncryptionInfo[];
    public static create(
      properties?: naturalcloudsyncv2.ISyncRequestMessage
    ): naturalcloudsyncv2.SyncRequestMessage;
    public static encode(
      message: naturalcloudsyncv2.ISyncRequestMessage,
      writer?: $protobuf.Writer
    ): $protobuf.Writer;
    public static encodeDelimited(
      message: naturalcloudsyncv2.ISyncRequestMessage,
      writer?: $protobuf.Writer
    ): $protobuf.Writer;
    public static decode(
      reader: $protobuf.Reader | Uint8Array,
      length?: number
    ): naturalcloudsyncv2.SyncRequestMessage;
    public static decodeDelimited(
      reader: $protobuf.Reader | Uint8Array
    ): naturalcloudsyncv2.SyncRequestMessage;
    public static verify(message: { [k: string]: any }): string | null;
    public static fromObject(object: { [k: string]: any }): naturalcloudsyncv2.SyncRequestMessage;
    public static toObject(
      message: naturalcloudsyncv2.SyncRequestMessage,
      options?: $protobuf.IConversionOptions
    ): { [k: string]: any };
    public toJSON(): { [k: string]: any };
    public static getTypeUrl(typeUrlPrefix?: string): string;
  }

  interface IClientInfo {
    uid?: string | null;
    pid?: string | null;
    cid?: string | null;
    aid?: string | null;
    appVer?: Long | null;
    msgVer?: number | null;
    enVer?: number | null;
  }

  class ClientInfo implements IClientInfo {
    constructor(properties?: naturalcloudsyncv2.IClientInfo);
    public uid: string;
    public pid: string;
    public cid: string;
    public aid: string;
    public appVer: Long;
    public msgVer: number;
    public enVer: number;
    public static create(
      properties?: naturalcloudsyncv2.IClientInfo
    ): naturalcloudsyncv2.ClientInfo;
    public static encode(
      message: naturalcloudsyncv2.IClientInfo,
      writer?: $protobuf.Writer
    ): $protobuf.Writer;
    public static encodeDelimited(
      message: naturalcloudsyncv2.IClientInfo,
      writer?: $protobuf.Writer
    ): $protobuf.Writer;
    public static decode(
      reader: $protobuf.Reader | Uint8Array,
      length?: number
    ): naturalcloudsyncv2.ClientInfo;
    public static decodeDelimited(
      reader: $protobuf.Reader | Uint8Array
    ): naturalcloudsyncv2.ClientInfo;
    public static verify(message: { [k: string]: any }): string | null;
    public static fromObject(object: { [k: string]: any }): naturalcloudsyncv2.ClientInfo;
    public static toObject(
      message: naturalcloudsyncv2.ClientInfo,
      options?: $protobuf.IConversionOptions
    ): { [k: string]: any };
    public toJSON(): { [k: string]: any };
    public static getTypeUrl(typeUrlPrefix?: string): string;
  }

  interface IQueryRequestMessage {
    queryType?: number | null;
    queryTable?: string | null;
    queryCond?: string | null;
  }

  class QueryRequestMessage implements IQueryRequestMessage {
    constructor(properties?: naturalcloudsyncv2.IQueryRequestMessage);
    public queryType: number;
    public queryTable: string;
    public queryCond: string;
    public static create(
      properties?: naturalcloudsyncv2.IQueryRequestMessage
    ): naturalcloudsyncv2.QueryRequestMessage;
    public static encode(
      message: naturalcloudsyncv2.IQueryRequestMessage,
      writer?: $protobuf.Writer
    ): $protobuf.Writer;
    public static encodeDelimited(
      message: naturalcloudsyncv2.IQueryRequestMessage,
      writer?: $protobuf.Writer
    ): $protobuf.Writer;
    public static decode(
      reader: $protobuf.Reader | Uint8Array,
      length?: number
    ): naturalcloudsyncv2.QueryRequestMessage;
    public static decodeDelimited(
      reader: $protobuf.Reader | Uint8Array
    ): naturalcloudsyncv2.QueryRequestMessage;
    public static verify(message: { [k: string]: any }): string | null;
    public static fromObject(object: { [k: string]: any }): naturalcloudsyncv2.QueryRequestMessage;
    public static toObject(
      message: naturalcloudsyncv2.QueryRequestMessage,
      options?: $protobuf.IConversionOptions
    ): { [k: string]: any };
    public toJSON(): { [k: string]: any };
    public static getTypeUrl(typeUrlPrefix?: string): string;
  }

  interface ISubscribeRequestMessage {
    subId?: string | null;
    subStore?: string | null;
    subTable?: string | null;
    subCond?: string | null;
  }

  class SubscribeRequestMessage implements ISubscribeRequestMessage {
    constructor(properties?: naturalcloudsyncv2.ISubscribeRequestMessage);
    public subId: string;
    public subStore: string;
    public subTable: string;
    public subCond: string;
    public static create(
      properties?: naturalcloudsyncv2.ISubscribeRequestMessage
    ): naturalcloudsyncv2.SubscribeRequestMessage;
    public static encode(
      message: naturalcloudsyncv2.ISubscribeRequestMessage,
      writer?: $protobuf.Writer
    ): $protobuf.Writer;
    public static encodeDelimited(
      message: naturalcloudsyncv2.ISubscribeRequestMessage,
      writer?: $protobuf.Writer
    ): $protobuf.Writer;
    public static decode(
      reader: $protobuf.Reader | Uint8Array,
      length?: number
    ): naturalcloudsyncv2.SubscribeRequestMessage;
    public static decodeDelimited(
      reader: $protobuf.Reader | Uint8Array
    ): naturalcloudsyncv2.SubscribeRequestMessage;
    public static verify(message: { [k: string]: any }): string | null;
    public static fromObject(object: {
      [k: string]: any;
    }): naturalcloudsyncv2.SubscribeRequestMessage;
    public static toObject(
      message: naturalcloudsyncv2.SubscribeRequestMessage,
      options?: $protobuf.IConversionOptions
    ): { [k: string]: any };
    public toJSON(): { [k: string]: any };
    public static getTypeUrl(typeUrlPrefix?: string): string;
  }

  interface IUnsubscribeRequestMessage {
    subRecId?: string | null;
    unSubStore?: string | null;
    unSubTable?: string | null;
    subKey?: number | null;
  }

  class UnsubscribeRequestMessage implements IUnsubscribeRequestMessage {
    constructor(properties?: naturalcloudsyncv2.IUnsubscribeRequestMessage);
    public subRecId: string;
    public unSubStore: string;
    public unSubTable: string;
    public subKey: number;
    public static create(
      properties?: naturalcloudsyncv2.IUnsubscribeRequestMessage
    ): naturalcloudsyncv2.UnsubscribeRequestMessage;
    public static encode(
      message: naturalcloudsyncv2.IUnsubscribeRequestMessage,
      writer?: $protobuf.Writer
    ): $protobuf.Writer;
    public static encodeDelimited(
      message: naturalcloudsyncv2.IUnsubscribeRequestMessage,
      writer?: $protobuf.Writer
    ): $protobuf.Writer;
    public static decode(
      reader: $protobuf.Reader | Uint8Array,
      length?: number
    ): naturalcloudsyncv2.UnsubscribeRequestMessage;
    public static decodeDelimited(
      reader: $protobuf.Reader | Uint8Array
    ): naturalcloudsyncv2.UnsubscribeRequestMessage;
    public static verify(message: { [k: string]: any }): string | null;
    public static fromObject(object: {
      [k: string]: any;
    }): naturalcloudsyncv2.UnsubscribeRequestMessage;
    public static toObject(
      message: naturalcloudsyncv2.UnsubscribeRequestMessage,
      options?: $protobuf.IConversionOptions
    ): { [k: string]: any };
    public toJSON(): { [k: string]: any };
    public static getTypeUrl(typeUrlPrefix?: string): string;
  }

  interface IServerStatus {
    timestamp?: Long | null;
  }

  class ServerStatus implements IServerStatus {
    constructor(properties?: naturalcloudsyncv2.IServerStatus);
    public timestamp: Long;
    public static create(
      properties?: naturalcloudsyncv2.IServerStatus
    ): naturalcloudsyncv2.ServerStatus;
    public static encode(
      message: naturalcloudsyncv2.IServerStatus,
      writer?: $protobuf.Writer
    ): $protobuf.Writer;
    public static encodeDelimited(
      message: naturalcloudsyncv2.IServerStatus,
      writer?: $protobuf.Writer
    ): $protobuf.Writer;
    public static decode(
      reader: $protobuf.Reader | Uint8Array,
      length?: number
    ): naturalcloudsyncv2.ServerStatus;
    public static decodeDelimited(
      reader: $protobuf.Reader | Uint8Array
    ): naturalcloudsyncv2.ServerStatus;
    public static verify(message: { [k: string]: any }): string | null;
    public static fromObject(object: { [k: string]: any }): naturalcloudsyncv2.ServerStatus;
    public static toObject(
      message: naturalcloudsyncv2.ServerStatus,
      options?: $protobuf.IConversionOptions
    ): { [k: string]: any };
    public toJSON(): { [k: string]: any };
    public static getTypeUrl(typeUrlPrefix?: string): string;
  }

  interface ISyncResponseMessage {
    msgInfo?: naturalcloudsyncv2.IMessageInfo | null;
    resInfo?: naturalcloudsyncv2.IResponseInfo | null;
    schemas?: naturalcloudsyncv2.ISchema[] | null;
    opData?: naturalcloudsyncv2.IOperationData[] | null;
    permRecs?: naturalcloudsyncv2.IPermissionRecord[] | null;
    updateResMsg?: naturalcloudsyncv2.IUpdateResponseMessage | null;
    queryResMsg?: naturalcloudsyncv2.IQueryResponseMessage | null;
    subResMsg?: naturalcloudsyncv2.ISubscribeResponseMessage[] | null;
    unSubResMsg?: naturalcloudsyncv2.IUnsubscribeResponseMessage[] | null;
    subPushMsg?: naturalcloudsyncv2.ISubscribePushMessage | null;
    enResInfo?: naturalcloudsyncv2.IEncryptionInfo[] | null;
    serverStatus?: naturalcloudsyncv2.IServerStatus | null;
  }

  class SyncResponseMessage implements ISyncResponseMessage {
    constructor(properties?: naturalcloudsyncv2.ISyncResponseMessage);
    public msgInfo?: naturalcloudsyncv2.IMessageInfo | null;
    public resInfo?: naturalcloudsyncv2.IResponseInfo | null;
    public schemas: naturalcloudsyncv2.ISchema[];
    public opData: naturalcloudsyncv2.IOperationData[];
    public permRecs: naturalcloudsyncv2.IPermissionRecord[];
    public updateResMsg?: naturalcloudsyncv2.IUpdateResponseMessage | null;
    public queryResMsg?: naturalcloudsyncv2.IQueryResponseMessage | null;
    public subResMsg: naturalcloudsyncv2.ISubscribeResponseMessage[];
    public unSubResMsg: naturalcloudsyncv2.IUnsubscribeResponseMessage[];
    public subPushMsg?: naturalcloudsyncv2.ISubscribePushMessage | null;
    public enResInfo: naturalcloudsyncv2.IEncryptionInfo[];
    public serverStatus?: naturalcloudsyncv2.IServerStatus | null;
    public static create(
      properties?: naturalcloudsyncv2.ISyncResponseMessage
    ): naturalcloudsyncv2.SyncResponseMessage;
    public static encode(
      message: naturalcloudsyncv2.ISyncResponseMessage,
      writer?: $protobuf.Writer
    ): $protobuf.Writer;
    public static encodeDelimited(
      message: naturalcloudsyncv2.ISyncResponseMessage,
      writer?: $protobuf.Writer
    ): $protobuf.Writer;
    public static decode(
      reader: $protobuf.Reader | Uint8Array,
      length?: number
    ): naturalcloudsyncv2.SyncResponseMessage;
    public static decodeDelimited(
      reader: $protobuf.Reader | Uint8Array
    ): naturalcloudsyncv2.SyncResponseMessage;
    public static verify(message: { [k: string]: any }): string | null;
    public static fromObject(object: { [k: string]: any }): naturalcloudsyncv2.SyncResponseMessage;
    public static toObject(
      message: naturalcloudsyncv2.SyncResponseMessage,
      options?: $protobuf.IConversionOptions
    ): { [k: string]: any };
    public toJSON(): { [k: string]: any };
    public static getTypeUrl(typeUrlPrefix?: string): string;
  }

  interface IResponseInfo {
    resCode?: number | null;
    resInfo?: string | null;
  }

  class ResponseInfo implements IResponseInfo {
    constructor(properties?: naturalcloudsyncv2.IResponseInfo);
    public resCode: number;
    public resInfo: string;
    public static create(
      properties?: naturalcloudsyncv2.IResponseInfo
    ): naturalcloudsyncv2.ResponseInfo;
    public static encode(
      message: naturalcloudsyncv2.IResponseInfo,
      writer?: $protobuf.Writer
    ): $protobuf.Writer;
    public static encodeDelimited(
      message: naturalcloudsyncv2.IResponseInfo,
      writer?: $protobuf.Writer
    ): $protobuf.Writer;
    public static decode(
      reader: $protobuf.Reader | Uint8Array,
      length?: number
    ): naturalcloudsyncv2.ResponseInfo;
    public static decodeDelimited(
      reader: $protobuf.Reader | Uint8Array
    ): naturalcloudsyncv2.ResponseInfo;
    public static verify(message: { [k: string]: any }): string | null;
    public static fromObject(object: { [k: string]: any }): naturalcloudsyncv2.ResponseInfo;
    public static toObject(
      message: naturalcloudsyncv2.ResponseInfo,
      options?: $protobuf.IConversionOptions
    ): { [k: string]: any };
    public toJSON(): { [k: string]: any };
    public static getTypeUrl(typeUrlPrefix?: string): string;
  }

  interface IPermissionRecord {
    tableName?: string | null;
    roleType?: string | null;
    readPerm?: boolean | null;
    upsertPerm?: boolean | null;
    deletePerm?: boolean | null;
  }

  class PermissionRecord implements IPermissionRecord {
    constructor(properties?: naturalcloudsyncv2.IPermissionRecord);
    public tableName: string;
    public roleType: string;
    public readPerm: boolean;
    public upsertPerm: boolean;
    public deletePerm: boolean;
    public static create(
      properties?: naturalcloudsyncv2.IPermissionRecord
    ): naturalcloudsyncv2.PermissionRecord;
    public static encode(
      message: naturalcloudsyncv2.IPermissionRecord,
      writer?: $protobuf.Writer
    ): $protobuf.Writer;
    public static encodeDelimited(
      message: naturalcloudsyncv2.IPermissionRecord,
      writer?: $protobuf.Writer
    ): $protobuf.Writer;
    public static decode(
      reader: $protobuf.Reader | Uint8Array,
      length?: number
    ): naturalcloudsyncv2.PermissionRecord;
    public static decodeDelimited(
      reader: $protobuf.Reader | Uint8Array
    ): naturalcloudsyncv2.PermissionRecord;
    public static verify(message: { [k: string]: any }): string | null;
    public static fromObject(object: { [k: string]: any }): naturalcloudsyncv2.PermissionRecord;
    public static toObject(
      message: naturalcloudsyncv2.PermissionRecord,
      options?: $protobuf.IConversionOptions
    ): { [k: string]: any };
    public toJSON(): { [k: string]: any };
    public static getTypeUrl(typeUrlPrefix?: string): string;
  }

  interface IUpdateResponseMessage {
    successRecCount?: number | null;
  }

  class UpdateResponseMessage implements IUpdateResponseMessage {
    constructor(properties?: naturalcloudsyncv2.IUpdateResponseMessage);
    public successRecCount: number;
    public static create(
      properties?: naturalcloudsyncv2.IUpdateResponseMessage
    ): naturalcloudsyncv2.UpdateResponseMessage;
    public static encode(
      message: naturalcloudsyncv2.IUpdateResponseMessage,
      writer?: $protobuf.Writer
    ): $protobuf.Writer;
    public static encodeDelimited(
      message: naturalcloudsyncv2.IUpdateResponseMessage,
      writer?: $protobuf.Writer
    ): $protobuf.Writer;
    public static decode(
      reader: $protobuf.Reader | Uint8Array,
      length?: number
    ): naturalcloudsyncv2.UpdateResponseMessage;
    public static decodeDelimited(
      reader: $protobuf.Reader | Uint8Array
    ): naturalcloudsyncv2.UpdateResponseMessage;
    public static verify(message: { [k: string]: any }): string | null;
    public static fromObject(object: {
      [k: string]: any;
    }): naturalcloudsyncv2.UpdateResponseMessage;
    public static toObject(
      message: naturalcloudsyncv2.UpdateResponseMessage,
      options?: $protobuf.IConversionOptions
    ): { [k: string]: any };
    public toJSON(): { [k: string]: any };
    public static getTypeUrl(typeUrlPrefix?: string): string;
  }

  interface IQueryResponseMessage {
    queryType?: number | null;
    isComplete?: boolean | null;
    aggQueryRes?: naturalcloudsyncv2.IAggregateQueryResult | null;
  }

  class QueryResponseMessage implements IQueryResponseMessage {
    constructor(properties?: naturalcloudsyncv2.IQueryResponseMessage);
    public queryType: number;
    public isComplete: boolean;
    public aggQueryRes?: naturalcloudsyncv2.IAggregateQueryResult | null;
    public static create(
      properties?: naturalcloudsyncv2.IQueryResponseMessage
    ): naturalcloudsyncv2.QueryResponseMessage;
    public static encode(
      message: naturalcloudsyncv2.IQueryResponseMessage,
      writer?: $protobuf.Writer
    ): $protobuf.Writer;
    public static encodeDelimited(
      message: naturalcloudsyncv2.IQueryResponseMessage,
      writer?: $protobuf.Writer
    ): $protobuf.Writer;
    public static decode(
      reader: $protobuf.Reader | Uint8Array,
      length?: number
    ): naturalcloudsyncv2.QueryResponseMessage;
    public static decodeDelimited(
      reader: $protobuf.Reader | Uint8Array
    ): naturalcloudsyncv2.QueryResponseMessage;
    public static verify(message: { [k: string]: any }): string | null;
    public static fromObject(object: { [k: string]: any }): naturalcloudsyncv2.QueryResponseMessage;
    public static toObject(
      message: naturalcloudsyncv2.QueryResponseMessage,
      options?: $protobuf.IConversionOptions
    ): { [k: string]: any };
    public toJSON(): { [k: string]: any };
    public static getTypeUrl(typeUrlPrefix?: string): string;
  }

  interface IAggregateQueryResult {
    isNull?: boolean | null;
    longRes?: Long | null;
    doubleRes?: number | null;
  }

  class AggregateQueryResult implements IAggregateQueryResult {
    constructor(properties?: naturalcloudsyncv2.IAggregateQueryResult);
    public isNull: boolean;
    public longRes?: Long | null;
    public doubleRes?: number | null;
    public result?: 'longRes' | 'doubleRes';
    public static create(
      properties?: naturalcloudsyncv2.IAggregateQueryResult
    ): naturalcloudsyncv2.AggregateQueryResult;
    public static encode(
      message: naturalcloudsyncv2.IAggregateQueryResult,
      writer?: $protobuf.Writer
    ): $protobuf.Writer;
    public static encodeDelimited(
      message: naturalcloudsyncv2.IAggregateQueryResult,
      writer?: $protobuf.Writer
    ): $protobuf.Writer;
    public static decode(
      reader: $protobuf.Reader | Uint8Array,
      length?: number
    ): naturalcloudsyncv2.AggregateQueryResult;
    public static decodeDelimited(
      reader: $protobuf.Reader | Uint8Array
    ): naturalcloudsyncv2.AggregateQueryResult;
    public static verify(message: { [k: string]: any }): string | null;
    public static fromObject(object: { [k: string]: any }): naturalcloudsyncv2.AggregateQueryResult;
    public static toObject(
      message: naturalcloudsyncv2.AggregateQueryResult,
      options?: $protobuf.IConversionOptions
    ): { [k: string]: any };
    public toJSON(): { [k: string]: any };
    public static getTypeUrl(typeUrlPrefix?: string): string;
  }

  interface ISubscribeResponseMessage {
    subRecId?: string | null;
    subId?: string | null;
    subKey?: number | null;
    subResCode?: number | null;
  }

  class SubscribeResponseMessage implements ISubscribeResponseMessage {
    constructor(properties?: naturalcloudsyncv2.ISubscribeResponseMessage);
    public subRecId: string;
    public subId: string;
    public subKey: number;
    public subResCode: number;
    public static create(
      properties?: naturalcloudsyncv2.ISubscribeResponseMessage
    ): naturalcloudsyncv2.SubscribeResponseMessage;
    public static encode(
      message: naturalcloudsyncv2.ISubscribeResponseMessage,
      writer?: $protobuf.Writer
    ): $protobuf.Writer;
    public static encodeDelimited(
      message: naturalcloudsyncv2.ISubscribeResponseMessage,
      writer?: $protobuf.Writer
    ): $protobuf.Writer;
    public static decode(
      reader: $protobuf.Reader | Uint8Array,
      length?: number
    ): naturalcloudsyncv2.SubscribeResponseMessage;
    public static decodeDelimited(
      reader: $protobuf.Reader | Uint8Array
    ): naturalcloudsyncv2.SubscribeResponseMessage;
    public static verify(message: { [k: string]: any }): string | null;
    public static fromObject(object: {
      [k: string]: any;
    }): naturalcloudsyncv2.SubscribeResponseMessage;
    public static toObject(
      message: naturalcloudsyncv2.SubscribeResponseMessage,
      options?: $protobuf.IConversionOptions
    ): { [k: string]: any };
    public toJSON(): { [k: string]: any };
    public static getTypeUrl(typeUrlPrefix?: string): string;
  }

  interface IUnsubscribeResponseMessage {
    unSubRecId?: string | null;
    unSubResCode?: number | null;
  }

  class UnsubscribeResponseMessage implements IUnsubscribeResponseMessage {
    constructor(properties?: naturalcloudsyncv2.IUnsubscribeResponseMessage);
    public unSubRecId: string;
    public unSubResCode: number;
    public static create(
      properties?: naturalcloudsyncv2.IUnsubscribeResponseMessage
    ): naturalcloudsyncv2.UnsubscribeResponseMessage;
    public static encode(
      message: naturalcloudsyncv2.IUnsubscribeResponseMessage,
      writer?: $protobuf.Writer
    ): $protobuf.Writer;
    public static encodeDelimited(
      message: naturalcloudsyncv2.IUnsubscribeResponseMessage,
      writer?: $protobuf.Writer
    ): $protobuf.Writer;
    public static decode(
      reader: $protobuf.Reader | Uint8Array,
      length?: number
    ): naturalcloudsyncv2.UnsubscribeResponseMessage;
    public static decodeDelimited(
      reader: $protobuf.Reader | Uint8Array
    ): naturalcloudsyncv2.UnsubscribeResponseMessage;
    public static verify(message: { [k: string]: any }): string | null;
    public static fromObject(object: {
      [k: string]: any;
    }): naturalcloudsyncv2.UnsubscribeResponseMessage;
    public static toObject(
      message: naturalcloudsyncv2.UnsubscribeResponseMessage,
      options?: $protobuf.IConversionOptions
    ): { [k: string]: any };
    public toJSON(): { [k: string]: any };
    public static getTypeUrl(typeUrlPrefix?: string): string;
  }

  interface ISubscribePushMessage {
    subRecId?: string | null;
    pushSeq?: Long | null;
    subKey?: number | null;
    subId?: string | null;
  }

  class SubscribePushMessage implements ISubscribePushMessage {
    constructor(properties?: naturalcloudsyncv2.ISubscribePushMessage);
    public subRecId: string;
    public pushSeq: Long;
    public subKey: number;
    public subId: string;
    public static create(
      properties?: naturalcloudsyncv2.ISubscribePushMessage
    ): naturalcloudsyncv2.SubscribePushMessage;
    public static encode(
      message: naturalcloudsyncv2.ISubscribePushMessage,
      writer?: $protobuf.Writer
    ): $protobuf.Writer;
    public static encodeDelimited(
      message: naturalcloudsyncv2.ISubscribePushMessage,
      writer?: $protobuf.Writer
    ): $protobuf.Writer;
    public static decode(
      reader: $protobuf.Reader | Uint8Array,
      length?: number
    ): naturalcloudsyncv2.SubscribePushMessage;
    public static decodeDelimited(
      reader: $protobuf.Reader | Uint8Array
    ): naturalcloudsyncv2.SubscribePushMessage;
    public static verify(message: { [k: string]: any }): string | null;
    public static fromObject(object: { [k: string]: any }): naturalcloudsyncv2.SubscribePushMessage;
    public static toObject(
      message: naturalcloudsyncv2.SubscribePushMessage,
      options?: $protobuf.IConversionOptions
    ): { [k: string]: any };
    public toJSON(): { [k: string]: any };
    public static getTypeUrl(typeUrlPrefix?: string): string;
  }
}
