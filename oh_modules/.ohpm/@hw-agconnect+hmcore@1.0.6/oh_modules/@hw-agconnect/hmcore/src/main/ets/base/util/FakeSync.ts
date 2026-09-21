import List from '@ohos.util.List';
import { Logger } from '../log/Logger';

const TAG = 'FakeSync';

export interface AsyncFactory<T> {
  instanceName(): string;

  create(): Promise<T>;
}

export class InstanceCreator<T> {
  constructor(factory: AsyncFactory<T>) {
    this.factory = factory;
  }

  factory: AsyncFactory<T>;
  instance: T = null;
  callbacks = new List();
}

export class FakeSync {
  static map = new Map<string, InstanceCreator<any>>();

  static createWithPromise<T>(factory: AsyncFactory<T>): Promise<T> {
    Logger.info(TAG, 'create sync instance name: ' + factory.instanceName());
    return new Promise((resolve) => {
      this.create(factory, (instance) => {
        resolve(instance);
      })
    });
  }

  static create<T>(factory: AsyncFactory<T>, callback: (instance) => void) {
    let name = factory.instanceName();
    let creator: InstanceCreator<T> = this.map.get(name);
    if (creator) {
      // 存在，直接返回
      if (creator.instance) {
        Logger.info(TAG, `${name} instance existed, return`);
        callback(creator.instance);
        return;
      }
      // 当前正在创建，插入callback,等待回调
      creator.callbacks.add(callback);
      this.map.set(name, creator);
      Logger.info(TAG, `${name} instance initialing, wait callback`);
      return;
    }
    creator = new InstanceCreator(factory);
    creator.callbacks.add(callback);
    this.map.set(name, creator);
    Logger.info(TAG, `${name} instance initialing, start create`);
    // 等待创建实例后，触发所有回调
    factory.create().then(result => {
      creator.instance = result;
      this.map.set(name, creator);

      let callbacks = this.map.get(name).callbacks;
      Logger.info(TAG, `${name} instance initialing, end create, callbacks length: ${callbacks.length}`);
      for (let index = 0; index < callbacks.length; index++) {
        let callback = callbacks.get(index);
        (callback as any)(result);
      }
    })
  }
}



