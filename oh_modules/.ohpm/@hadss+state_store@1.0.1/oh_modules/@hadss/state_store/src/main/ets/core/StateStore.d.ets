// "use shared"
import { lang } from '@kit.ArkTS';
import { Store } from '../types/Store';
import { Reducer } from '../types/Reducers';
import { Action, SendableAction } from '../types/Actions';
import { Middleware } from '../types/Middleware';
@Sendable
declare class InnerStateStore {
    /**
     * @description Create the corresponding store object in memory based on the storeId.
     * @param storeId
     * @param actions
     * @param model
     * @param middlewares
     * @returns
     */
    createStore<T>(storeId: string, state: T, actions: Reducer<T>, middlewares?: Middleware<T>[]): Store<T>;
    /**
     * @description Retrieve the corresponding store object from memory based on the storeId.
     * @param storeId
     * @returns
     */
    getStore<T>(storeId: string): Store<T>;
    /**
     * @description Destroy the corresponding store object in memory based on the storeId.
     * @param storeId
     */
    destroyStore(storeId: string): void;
    /**
     * @description Create an action object.
     * @param type
     * @param payload
     * @returns
     */
    createAction(type: string, payload?: ESObject): Action;
    /**
     * @description The child thread creates a Sendable format Action object.
     * @param storeId
     * @param type
     * @param payload
     * @returns
     */
    createSendableAction(storeId: string, type: string, payload?: lang.ISendable | null): SendableAction;
    /**
     * @description The main thread receives a SendableAction object and triggers the reducer function.
     * @param sendableAction
     */
    receiveSendableAction<T>(sendableAction: SendableAction): void;
    /**
     * @description Merge multiple reducers of an observed object into a single reducer
     * @param reducers
     * @returns
     */
    combineReducers<T>(reducers: Record<string, Reducer<ESObject>>): (state: T, action: Action) => null;
}
export declare let StateStore: InnerStateStore;
export {};
