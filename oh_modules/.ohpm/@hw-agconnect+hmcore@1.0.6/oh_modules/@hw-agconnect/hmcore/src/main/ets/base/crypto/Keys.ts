/**
 * 参考Java实现，根据三段组件获取password
 * @param xBytes 组件x
 * @param yBytes 组件y
 * @param zBytes 组件x
 */
export function getKey(xBytes: any, yBytes: any, zBytes: any) {
  return bytesXor(bytesShift(bytesXor(bytesShift(xBytes, -4), yBytes), 6), zBytes);
}

/**
 * 对两个byte数组中的byte值，逐一且一一对应进行异或运算。
 * 返回result的初始化类型禁止修改，java才做会对int转byte强制转换
 * js采用Int8Array无法获取到正确的结果
 *
 * @param left 左操作数
 * @param right 右操作数
 */
function bytesXor(left: any, right: any) {
  if (!left || !right) {
    throw new Error('left or right must not be null.');
  }
  if (left.length != right.length) {
    throw new Error('left and right must be the same length.');
  }
  // 此处必须初始化Array,不能初始化为Int8Array
  let result = new Array();
  for (let i = 0; i < left.length; i++) {
    result[i] = left[i] ^ right[i];
  }
  return result;
}

/**
 * 对byte数组中的byte值，逐一进行移位运算。
 * @param bytes 原始数组
 * @param steps 小于0，左移[-steps]；大于0，右移[steps]
 */
function bytesShift(bytes: any, steps: number) {
  if (!bytes) {
    throw new Error('bytes can not be null.');
  }
  for (let i = 0; i < bytes.length; i++) {
    if (steps < 0) {
      bytes[i] = bytes[i] << -steps;
    } else {
      bytes[i] = bytes[i] >> steps;
    }
  }
  return bytes;
}
