import { Reducer } from '../types/Reducers';
import { Store } from '../types/Store';
import { Middleware } from '../types/Middleware';
/**
 * @description Create a corresponding store object based on the `storeId` to manage
 * the application's global state, and update the state by dispatching actions.
 * @param reducer
 * @param initialState
 * @param enhancer
 * @returns
 */
export declare function createStore<T>(initialState: T, reducer: Reducer<T>, middlewares?: Middleware<T>[]): Store<T>;
