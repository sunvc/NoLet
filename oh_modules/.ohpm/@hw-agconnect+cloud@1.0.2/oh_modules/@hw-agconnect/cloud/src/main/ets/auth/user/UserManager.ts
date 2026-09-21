import { AuthBackend } from '../server/AuthBackend';
import { UserRawData } from './UserRawData';
import { StoredManager } from '../storage/StoredManager';
import { AuthDefaultUser as AuthDefaultUser } from './AuthDefaultUser';

export class UserManager {
  storedManager: StoredManager;
  authBackend: AuthBackend;
  user: AuthDefaultUser;

  public async makeUserInstance(userRawData: UserRawData): Promise<AuthDefaultUser> {
    await this.disposeUserInstance();
    this.user = AuthDefaultUser.fromRawData(userRawData);
    this.user.setStoreManager(this.storedManager);
    this.user.setAuthBackend(this.authBackend);
    await this.user.syncToStorage();
    return this.user;
  }

  public async disposeUserInstance(): Promise<void> {
    await this.currentUserInstance();
    if (this.user) {
      await this.user.dispose();
      this.user = null;
    }
  }

  async currentUserInstance(): Promise<AuthDefaultUser | null> {
    if (this.user) {
      return this.user;
    }

    let data = <UserRawData>await this.storedManager.loadFromStorage();
    if (data == null) {
      return null;
    }
    this.user = AuthDefaultUser.fromRawData(data);
    this.user.setStoreManager(this.storedManager);
    this.user.setAuthBackend(this.authBackend);
    return this.user;
  }
}

export class UserManagerBuilder {
  private manager: UserManager;

  constructor() {
    this.reset();
  }

  public setAuthBackend(authBackend: AuthBackend): UserManagerBuilder {
    this.manager.authBackend = authBackend;
    return this;
  }

  public setStoredManager(storeManager: StoredManager): UserManagerBuilder {
    this.manager.storedManager = storeManager;
    return this;
  }

  private reset() {
    this.manager = new UserManager();
  }

  public build(): UserManager {
    let res = this.manager;
    this.reset();
    return res;
  }
}
