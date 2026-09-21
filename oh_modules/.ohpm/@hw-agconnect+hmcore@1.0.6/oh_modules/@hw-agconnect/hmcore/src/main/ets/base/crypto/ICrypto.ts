export interface ICrypto {
  encrypt(plain: string): Promise<string>;
  decrypt(cipher: string): Promise<string>;
}
