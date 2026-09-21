// LazyForEach 通用数据源。整表替换后触发全量重载（onDataReloaded），
// 框架按 key 复用未变行、销毁消失行、新建新增行——语义等价 ForEach 换数组。
// 复用行不会重绑 @Param，故数据层仍需就地更新对象（见 MessagesState.syncFlat/syncGroups）。
export class BasicDataSource<T> implements IDataSource {
  private listeners: DataChangeListener[] = [];
  private data: T[] = [];

  totalCount(): number {
    return this.data.length;
  }

  getData(index: number): T {
    return this.data[index];
  }

  registerDataChangeListener(listener: DataChangeListener): void {
    if (this.listeners.indexOf(listener) < 0) {
      this.listeners.push(listener);
    }
  }

  unregisterDataChangeListener(listener: DataChangeListener): void {
    const i = this.listeners.indexOf(listener);
    if (i >= 0) {
      this.listeners.splice(i, 1);
    }
  }

  // 整表替换并通知全量重载
  replaceAll(items: T[]): void {
    this.data = items;
    this.listeners.forEach((l: DataChangeListener): void => l.onDataReloaded());
  }
}
