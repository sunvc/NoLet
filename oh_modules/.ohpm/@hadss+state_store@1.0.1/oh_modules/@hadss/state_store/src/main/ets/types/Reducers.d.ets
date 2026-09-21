import { Action } from './Actions';
export type Reducer<T> = (state: T, action: Action) => (() => Promise<void>) | null;
export type AsyncFunction = () => Promise<void>;
