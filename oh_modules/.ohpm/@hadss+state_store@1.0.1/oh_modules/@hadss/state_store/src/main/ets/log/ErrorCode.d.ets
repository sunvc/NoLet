declare enum StoreError {
    /**
     * storeId not found
     */
    STORE_NOT_FOUND = "STORE_NOT_FOUND",
    /**
     * storeId already exists in memory, avoid duplicate creation.
     */
    STORE_ALREADY_EXISTS = "STORE_ALREADY_EXISTS",
    /**
     * action.type is empty
     */
    INVALID_ACTION_TYPE = "INVALID_ACTION_TYPE",
    INVALID_STATE_ACCESS = "INVALID_STATE_ACCESS"
}
interface ErrorDetail {
    errorCode: number;
    errorMsg: string;
}
declare const DEFINED_ERROR: Map<string, ErrorDetail>;
export { StoreError, DEFINED_ERROR };
