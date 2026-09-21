export class Response {
  responseCode: number;
  result?: string | Object | ArrayBuffer;
  header?: Object;
  message?: string;
}
