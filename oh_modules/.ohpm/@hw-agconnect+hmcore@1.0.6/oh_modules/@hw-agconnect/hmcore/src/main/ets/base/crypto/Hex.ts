/**
 * Convert a hex string to a byte array
 */
export function bytesToHex(bytes: any): string {
  if (!bytes || bytes.length == 0) {
    throw new Error('bytes can not be null.');
  }
  for (var hex = [], i = 0; i < bytes.length; i++) {
    var current = bytes[i] < 0 ? bytes[i] + 256 : bytes[i];
    hex.push((current >>> 4).toString(16));
    hex.push((current & 0xf).toString(16));
  }
  return hex.join('').toUpperCase();
}

/**
 * Convert a hex string to a byte array
 */
export function hexToBytes(hex: any): Int8Array {
  if (!hex) {
    throw new Error('hex can not be null.');
  }
  for (var bytes = new Int8Array(hex.length / 2), c = 0; c < hex.length; c += 2) {
    let value = parseInt(hex.substr(c, 2), 16);
    bytes[c / 2] = value < 128 ? value : value - 256;
  }
  return bytes;
}
