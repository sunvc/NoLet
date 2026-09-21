import { SecretKeyManager } from './SecretKeyManager';
import { EncryptTaskManager } from '../sync/EncryptTaskManager';

// check dataKey status to every 30 seconds
const TASK_SCHEDULE_INTERVAL = 30 * 1000;
// 15min
const MAX_SCHEDULE_TIME = 9e5;

export class EntireEncryptInterval {
  private intervalTimeOut = 0;
  private secretKeyManager: SecretKeyManager | undefined;
  private encryptTaskManager: EncryptTaskManager | undefined;
  private timeOutStateMachine = false;
  private firstTime = 0;

  public constructor() {}

  public setIntervalCleanKey(operationStatus: boolean) {
    this.firstTime = Date.now();
    if (operationStatus || this.timeOutStateMachine) {
      return;
    }

    // only support browser or quickapp; not support nodejs
    // if support nodejs, please modify setInterval; nodejs setInterval return Nodejs.timeout not number
    // eslint-disable-next-line @typescript-eslint/ban-ts-comment
    // @ts-ignore
    this.intervalTimeOut = setInterval(() => {
      // clear key
      if (Date.now() - this.firstTime >= MAX_SCHEDULE_TIME) {
        if (this.secretKeyManager) {
          this.secretKeyManager.clearDataKeyInfo();
        }
        this.secretKeyManager?.getEntireEncryption().clearUserKeysInfo();
        this.encryptTaskManager!.tryToDisconnectWhenClearUserKey();
        this.timeOutStateMachine = false;
        clearInterval(this.intervalTimeOut);
      }
    }, TASK_SCHEDULE_INTERVAL);
    this.timeOutStateMachine = true;
  }

  public saveSecretKeyManager(secretKeyManager: SecretKeyManager): void {
    this.secretKeyManager = secretKeyManager;
  }

  public saveEncryptTaskManager(encryptTaskManager: EncryptTaskManager): void {
    this.encryptTaskManager = encryptTaskManager;
  }
}
