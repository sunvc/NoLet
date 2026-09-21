import { Dispatch } from './Dispatch';
export interface Store<T> {
    /**
     * Get observed State
     */
    getState: () => T;
    /**
     * Dispatches an action. It is the way to trigger a state change.
     *
     * The base implementation only supports plain object actions.
     */
    dispatch: Dispatch;
}
