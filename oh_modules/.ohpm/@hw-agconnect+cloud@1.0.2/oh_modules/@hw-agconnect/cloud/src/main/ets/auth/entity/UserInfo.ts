export class UserInfo {
  private uid: string;
  private displayName: string;
  private photoUrl: string;
  private phone: string;
  private email: string;
  private provider: number;
  private openId: string;
  private emailVerified: number;
  private passwordSetted: number;

  constructor() {
    this.uid = '';
    this.displayName = '';
    this.photoUrl = '';
    this.phone = '';
    this.email = '';
    this.provider = -1;
    this.openId = '';
    this.emailVerified = 0;
    this.passwordSetted = 0;
  }

  public getUid(): string {
    return this.uid;
  }

  public setUid(uid: string): void {
    this.uid = uid;
  }

  public getDisplayName(): string {
    return this.displayName;
  }

  public setDisplayName(displayName: string): void {
    this.displayName = displayName;
  }

  public getPhotoUrl(): string {
    return this.photoUrl;
  }

  public setPhotoUrl(photoUrl: string): void {
    this.photoUrl = photoUrl;
  }

  public getPhone(): string {
    return this.phone;
  }

  public setPhone(phone: string): void {
    this.phone = phone;
  }

  public getEmail(): string {
    return this.email;
  }

  public setEmail(email: string): void {
    this.email = email;
  }

  public getProvider(): number {
    return this.provider;
  }

  public setProvider(provider: number): void {
    this.provider = provider;
  }

  public getOpenId(): string {
    return this.openId;
  }

  public setOpenId(openId: string): void {
    this.openId = openId;
  }

  public getEmailVerified(): number {
    return this.emailVerified;
  }

  public setEmailVerified(emailVerified: number): void {
    this.emailVerified = emailVerified;
  }

  public getPasswordSetted(): number {
    return this.passwordSetted;
  }

  public setPasswordSetted(passwordSetted: number): void {
    this.passwordSetted = passwordSetted;
  }
}
