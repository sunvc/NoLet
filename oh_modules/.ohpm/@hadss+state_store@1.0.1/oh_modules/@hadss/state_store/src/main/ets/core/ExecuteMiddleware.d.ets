import { Action } from '../types/Actions';
import { MiddlewareFuncType } from '../types/Middleware';
/**
 * Execution logic of the beforeAction and afterAction functions in the middleware.
 */
export declare const executeMiddleware: <T>(state: T, action: Action, subscribers: MiddlewareFuncType<T>[], resetAction: Action[]) => Promise<boolean>;
