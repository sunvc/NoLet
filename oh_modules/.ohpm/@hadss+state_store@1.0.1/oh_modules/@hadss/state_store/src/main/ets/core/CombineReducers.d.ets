import { Reducer } from '../types/Reducers';
import { Action } from '../types/Actions';
export declare function combineReducers<State>(reducers: Record<string, Reducer<ESObject>>): (state: State, action: Action) => any;
