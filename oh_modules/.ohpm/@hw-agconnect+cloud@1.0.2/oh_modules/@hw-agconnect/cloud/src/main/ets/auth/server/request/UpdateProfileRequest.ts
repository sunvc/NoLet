import { AuthBaseRequest } from './AuthBaseRequest';

export class UpdateProfileRequest extends AuthBaseRequest {
  protected readonly URL_PATH_SURFFIX = '/user-profile';

  private displayName: string = '';

  private photoUrl: string = '';

  public setDisplayName(displayName: string): void {
    this.displayName = displayName;
  }

  public setPhotoUrl(photoUrl: string): void {
    this.photoUrl = photoUrl;
  }

  async body(): Promise<any> {
    return {
      displayName: this.displayName,
      photoUrl: this.photoUrl
    };
  }
}
