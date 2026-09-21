// @keepTs
// @ts-nocheck
import cloudCommon from "@hms.core.deviceCloudGateway.cloudCommon";
export declare class CloudCommonAuthProvider implements cloudCommon.AuthProvider {
    private static AGC_AUTH_PREFIX;
    getAccessToken(isForceRefresh: boolean): Promise<string>;
}
