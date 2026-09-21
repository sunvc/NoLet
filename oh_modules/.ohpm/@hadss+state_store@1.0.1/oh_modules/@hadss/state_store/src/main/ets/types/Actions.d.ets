import { lang } from '@kit.ArkTS';
/**
 * Actions are the way to get data into the store.
 * The `payload` property is used to pass the specific data for the action.
 *
 */
export declare class Action {
    readonly type: string;
    payload: ESObject;
    constructor(type: string, payload?: ESObject);
    setPayload(payload: ESObject): this;
}
/**
 * The sendable action supports passing data between threads without deserialization.
 */
@Sendable
export declare class SendableAction {
    readonly storeId: string;
    readonly type: string;
    payload: lang.ISendable | null;
    constructor(storeId: string, type: string, payload?: lang.ISendable | null);
    setPayload(payload: lang.ISendable): this;
}
