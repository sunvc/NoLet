import { AuthUserExtra } from '../../Auth';
import { BaseResponse } from '@hw-agconnect/hmcore';

export class UserExtraResponse extends BaseResponse {
  displayName: string = '';
  photoUrl: string = '';
  emailVerified: number = 0;
  passwordSetted: number = 0;
  email: string = '';
  phone: string = '';
  userExtra: UserExtra = new UserExtra();

  /**
   * 构造方法，给定一些默认值，需要改变时，通过set方法设置
   */
  constructor() {
    super();
  }

  constructResponse(response: any): boolean {
    this.displayName = response.displayName;
    this.photoUrl = response.photoUrl;
    this.emailVerified = response.emailVerified;
    this.passwordSetted = response.passwordSetted;
    this.email = response.email;
    this.phone = response.phone;
    this.userExtra.createTime = response.userMetaData.createTime;
    this.userExtra.lastSignInTime = response.userMetaData.lastSignInTime;

    this.ret.setMsg(response.ret.msg);
    this.ret.setCode(response.ret.code);
    return true;
  }
}

export class UserExtra implements AuthUserExtra {
  createTime: string = '';
  lastSignInTime: string = '';

  getCreateTime(): string {
    return this.createTime;
  }

  getLastSignInTime(): string {
    return this.lastSignInTime;
  }
}
