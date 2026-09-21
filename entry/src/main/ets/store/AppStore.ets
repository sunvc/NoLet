import { Middleware, MiddlewareStatus, StateStore } from '@hadss/state_store';
import type { Action, MiddlewareFuncType, Store } from '@hadss/state_store';
import { common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { AppStoreModel } from '../model/AppStoreModel';
import { appReducer } from './AppReducer';
import { AppActionType, AppActions } from './AppActions';
import { initAppPrefs, readPersistedState, writePersistedState } from './AppPersistence';
import type { PersistedState } from './AppPersistence';

export { AppActions };

const DOMAIN = 0x0000;
const TAG = 'AppStore';
const APP_STORE_ID: string = 'app';

// 每次状态变更后把模型写入 Preferences；hydrate 本身不落盘
class PersistMiddleware extends Middleware<AppStoreModel> {
  public beforeAction: MiddlewareFuncType<AppStoreModel>;
  public afterAction: MiddlewareFuncType<AppStoreModel>;

  constructor() {
    super();
    this.beforeAction = (): MiddlewareStatus => MiddlewareStatus.NEXT;
    this.afterAction = async (state: AppStoreModel, action: Action): Promise<MiddlewareStatus> => {
      if (action.type !== AppActionType.HYDRATE) {
        try {
          await writePersistedState(state);
        } catch (e) {
          hilog.error(DOMAIN, TAG, `persist failed: ${(e as Error).message}`);
        }
      }
      return MiddlewareStatus.NEXT;
    };
  }
}

// 全局唯一 store：模块加载时创建，不依赖 UI 实例，任何位置 import 即可用
export const appStore: Store<AppStoreModel> =
  StateStore.createStore(APP_STORE_ID, new AppStoreModel(), appReducer, [new PersistMiddleware()]);

// 启动时从 Preferences 恢复。Preferences 无 UI 实例要求，可在 Ability.onCreate 中调用
export async function hydrateAppStore(context: common.Context): Promise<void> {
  await initAppPrefs(context);
  const data: PersistedState | null = readPersistedState();
  if (data !== null) {
    await appStore.dispatch(AppActions.hydrate(data));
    hilog.info(DOMAIN, TAG, `hydrated, servers=${appStore.getState().servers.length}`);
  }
}
