export function isFunction(p: unknown): p is Function {
  return typeof p === 'function';
}

export function isDefined<T>(p: T | null | undefined): p is T {
  return p != null;
}

export namespace ObserverUtil {
  export type NextFn<T> = (value: T) => void;
  export type ErrorFn = (error: Error) => void;
  export type CompleteFn = () => void;
  export type Unsubscribe = () => void;

  export interface Observer<T> {
    next?: NextFn<T> | null;
    error?: ErrorFn | null;
    complete?: CompleteFn | null;
  }

  export type Subscribe<T> = (
    next?: NextFn<T> | Observer<T> | null,
    error?: ErrorFn | null,
    complete?: CompleteFn | null
  ) => Unsubscribe;

  export class ObserverImpl<T> implements Observer<T> {
    next?: NextFn<T> | null;
    error?: ErrorFn | null;
    complete?: CompleteFn | null;

    constructor(
      nextOrObserver?: NextFn<T> | Observer<T> | null,
      error?: ErrorFn | null,
      complete?: CompleteFn | null
    ) {
      const isFunctions = isFunction(nextOrObserver) || isDefined(error) || isDefined(complete);
      if (isFunctions) {
        this.complete = complete || null;
        this.next = nextOrObserver as NextFn<T> | null;
        this.error = error || null;
      } else {
        let observer = nextOrObserver as {
          next?: NextFn<T> | null;
          error?: ErrorFn | null;
          complete?: CompleteFn | null;
        };
        this.complete = observer.complete || null;
        this.next = observer.next || null;
        this.error = observer.error || null;
      }
    }
  }
}
