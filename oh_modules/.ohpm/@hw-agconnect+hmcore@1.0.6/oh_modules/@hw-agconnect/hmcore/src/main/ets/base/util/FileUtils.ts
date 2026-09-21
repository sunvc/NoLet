export class File {
  name: string;
  modifiedTime: number;
  constructor(name: string, modifiedTime: number) {
    this.name = name;
    this.modifiedTime = modifiedTime;
  }
}
