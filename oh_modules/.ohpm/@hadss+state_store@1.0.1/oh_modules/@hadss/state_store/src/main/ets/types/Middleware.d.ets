import { Action } from './Actions';
import { MiddlewareStatus } from '../constants/MiddlewareStatus';
export type MiddlewareFuncType<T> = ((state: T, action: Action) => MiddlewareStatus | Action) | ((state: T, action: Action) => Promise<MiddlewareStatus | Action>);
export declare abstract class Middleware<T> {
    /**
     * If an actionType is defined, the middleware will only execute when
     * the corresponding dispatch triggers the specified type.
     */
    actionType: string;
    abstract beforeAction: MiddlewareFuncType<T>;
    abstract afterAction: MiddlewareFuncType<T>;
}
