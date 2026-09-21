/**
 * Copyright (c) Huawei Technologies Co., Ltd. 2020-2021. All rights reserved.
 */

import { FieldType } from './SchemaNamespace';
import { Utils } from './Utils';
// @ts-ignore
import Long from 'long';
import base64 from '@protobufjs/base64';

const MAX_FLOAT_PRECISION = 6;
const MAX_DOUBLE_PRECISION = 15;

type SerializerFn = (value: any) => unknown;
type DeserializerFn = (value: any) => unknown;

export const Serializers: { [key: number]: SerializerFn } = {};

export const Deserializers: { [key: number]: DeserializerFn } = {};

function addSerializer(type: FieldType, serializer: SerializerFn) {
  Serializers[type] = serializer;
}

function transformNumber(value: unknown, precision: number) {
  if (Utils.isNullOrUndefined(value)) {
    return undefined;
  }
  if (typeof value === 'number') {
    return Number(value.toPrecision(precision)).valueOf();
  }
  return undefined;
}

addSerializer(FieldType.Date, (date: Date) => {
  if (!(date instanceof Date)) {
    return undefined;
  }
  return Long.fromNumber(date.getTime());
});

addSerializer(FieldType.Float, (value: unknown) => {
  return transformNumber(value, MAX_FLOAT_PRECISION);
});

addSerializer(FieldType.Double, (value: unknown) => {
  return transformNumber(value, MAX_DOUBLE_PRECISION);
});

function addDeserializer(type: FieldType, deserializer: DeserializerFn) {
  Deserializers[type] = deserializer;
}

addDeserializer(FieldType.Date, (value: unknown): Date | undefined => {
  if (Utils.isNullOrUndefined(value)) {
    return undefined;
  }
  if (value instanceof Long) {
    return new Date((value as Long).toNumber());
  }

  if (value instanceof Date) {
    return value;
  }
  return undefined;
});

addDeserializer(FieldType.ByteArray, (value: unknown): Uint8Array | undefined => {
  if (value instanceof Uint8Array) {
    return value;
  } else if (typeof value === 'string') {
    const buffer = new ArrayBuffer(value.length);
    const array = new Uint8Array(buffer);
    const length = base64.decode(value, array, 0);
    return array.slice(0, length);
  }
  return undefined;
});

addDeserializer(FieldType.Float, (value: unknown): number | undefined => {
  return transformNumber(value, MAX_FLOAT_PRECISION);
});

addDeserializer(FieldType.Double, (value: unknown): number | undefined => {
  return transformNumber(value, MAX_DOUBLE_PRECISION);
});
