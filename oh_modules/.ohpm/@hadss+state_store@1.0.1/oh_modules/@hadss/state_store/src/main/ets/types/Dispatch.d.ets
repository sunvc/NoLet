import { Action } from './Actions';
export type Dispatch = (action: Action) => Promise<void>;
