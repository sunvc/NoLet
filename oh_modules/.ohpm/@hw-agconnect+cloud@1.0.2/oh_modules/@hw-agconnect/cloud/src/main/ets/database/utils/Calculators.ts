/**
 * Copyright (c) Huawei Technologies Co., Ltd. 2020-2021. All rights reserved.
 */

// This is for 64bit JVM Object.
import { FieldType } from './SchemaNamespace';
import { Utils } from './Utils';

type CalculatorFn = (value: any) => number;

export const Calculators: { [key: number]: CalculatorFn } = {};

function addCalculator(type: FieldType, calculator: CalculatorFn) {
  Calculators[type] = calculator;
}

function getStrLength(str: unknown): number {
  if (Utils.isNullOrUndefined(str)) {
    return 0;
  }
  let length = 0;
  const temp = str as string;
  for (let i = 0; i < temp.length; i = i + 1) {
    length = length + getCharArrayLength(temp, i);
  }
  return length;
}

function getCharArrayLength(str: string, index: number): number {
  const code = str.charCodeAt(index);
  if (code >> 11 > 0) {
    return 3;
  }
  if (code >> 7 > 0) {
    return 2;
  }
  return 1;
}

addCalculator(FieldType.Integer, (_: unknown) => 4);
addCalculator(FieldType.String, (value: string) => {
  return getStrLength(value);
});
addCalculator(FieldType.Short, (_: unknown) => 2);
addCalculator(FieldType.Long, (_: unknown) => 8);
addCalculator(FieldType.Boolean, (_: unknown) => 1);
addCalculator(FieldType.Byte, (_: unknown) => 1);
addCalculator(FieldType.Float, (_: unknown) => 4);
addCalculator(FieldType.Double, (_: unknown) => 8);
addCalculator(FieldType.ByteArray, (value: ArrayBuffer) => (value ? value.byteLength : 0));
addCalculator(FieldType.Date, (_: unknown) => 8);
addCalculator(FieldType.Text, (text: string) => {
  return getStrLength(text);
});
