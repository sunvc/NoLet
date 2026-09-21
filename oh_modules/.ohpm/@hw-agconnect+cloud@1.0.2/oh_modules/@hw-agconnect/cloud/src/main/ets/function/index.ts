export interface FunctionOptions {
  name: string;
  version?: string;
  timeout?: number;
  params?: any;
  emulatorUrl?: string;
}

export interface FunctionResult {
  getValue(): any;
}
