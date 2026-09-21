/**
 * Copyright (c) Huawei Technologies Co., Ltd. 2020-2020. All rights reserved.
 */

export type Condition<T> = (state: State<T>) => boolean;

export type Executor<T> = (state: State<T>) => void;

export class State<T> {
  private value_: T | undefined = undefined;
  private actions: { [id: string]: Action<T> } = {};

  constructor(value?: T) {
    this.value_ = value;
  }

  get value(): T | undefined {
    return this.value_;
  }

  set value(value: T | undefined) {
    this.value_ = value;
    const keys = Object.getOwnPropertyNames(this.actions);
    for (const key of keys) {
      const action = this.actions[key];
      if (action?.isMeetCondition(this)) {
        action.execute(this);
      }
    }
  }

  public register(action: Action<T>) {
    this.actions[action.id] = action;
  }

  public unregister(id: string) {
    delete this.actions[id];
  }

  public hasNoAction() {
    const keys = Object.getOwnPropertyNames(this.actions);
    return keys.length === 0;
  }

  public release() {
    this.actions = {};
    this.value_ = undefined;
  }
}

export class Action<T> {
  readonly id: string;
  readonly isOnce: boolean;
  private func: Executor<T>;
  private condition: Condition<T>;
  private isTimeout = false;
  private executed = false;
  private isRegistered = false;

  constructor(isOnce: boolean, func: Executor<T>, id: string, condition?: Condition<T>) {
    this.isOnce = isOnce;
    this.id = id;
    this.func = func;
    this.condition = condition ? condition : _ => true;
  }

  public get isExecuted() {
    return this.executed;
  }

  public isMeetCondition(state: State<T>) {
    return this.isTimeout === false && this.condition(state);
  }

  public withTimeout(duration: number, handle?: () => void) {
    setTimeout(() => {
      if (this.isExecuted) {
        return;
      }
      this.isTimeout = true;
      if (handle) {
        handle();
      }
    }, duration);
    return this;
  }

  public execute(state: State<T>): void {
    if (this.isTimeout) {
      return;
    }
    if (!this.isRegistered) {
      state.register(this);
    }
    if (this.condition(state)) {
      this.executeAndTryUnregister(state);
    }
  }

  private executeAndTryUnregister(state: State<T>) {
    this.executed = true;
    try {
      this.func(state);
    } catch (e) {
      setTimeout(() => {
        throw e;
      }, Math.floor(0));
    }
    if (this.isOnce) {
      state.unregister(this.id);
    }
  }
}
