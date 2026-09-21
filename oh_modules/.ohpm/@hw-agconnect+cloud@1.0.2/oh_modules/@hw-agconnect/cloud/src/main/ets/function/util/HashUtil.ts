import { sha256 } from '@hw-agconnect/hmcore';
import BigNumber from 'bignumber.js';

const BASE_36 = '0123456789abcdefghijklmnopqrstuvwxyz';
const DIVISOR = 36;
const BIT_MAX = 35;

export async function hash(value: string) {
  let hexRes = await sha256(value);
  hexRes = '0x' + hexRes;
  let intValue = new BigNumber(hexRes,16);
  let result = encode(intValue);
  if (result.length >= 8) {
    return result.substring(0,8);
  }
  return result;
}

function encode(num: BigNumber): string {
  let res: string = '';
  while (num.isGreaterThan(BIT_MAX)) {
    let remainder = num.modulo(DIVISOR);
    res = BASE_36.charAt(remainder.toNumber()) + res;
    num = num.dividedToIntegerBy(DIVISOR);
  }
  res = BASE_36.charAt(num.toNumber()) + res;
  return res;
}
