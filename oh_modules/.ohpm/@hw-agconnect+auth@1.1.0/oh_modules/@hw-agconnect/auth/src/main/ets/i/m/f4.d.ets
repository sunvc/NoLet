// @keepTs
// @ts-nocheck
import { AuthBaseRequest } from "./y3";
export declare class UpdateProfileRequest extends AuthBaseRequest {
    protected readonly URL_PATH_SURFFIX = "/user-profile";
    private displayName;
    private photoUrl;
    setDisplayName(displayName: string): void;
    setPhotoUrl(photoUrl: string): void;
    body(): Promise<Record<string, object | number | string>>;
}
