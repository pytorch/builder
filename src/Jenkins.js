import { get_request } from './Utils.js';

export class Jenkins {
  url(s) {
    return "https://ci.pytorch.org/jenkins/" + s + "/api/json";
  }
  link(s) {
    return "https://ci.pytorch.org/jenkins/" + s;
  }

  async computer(options) { return get_request(this.url("computer"), options); }
  async queue(options) { return get_request(this.url("queue"), options); }
  async job(v, options) { return get_request(this.url("job/" + v), options); }
}

const jenkins = new Jenkins();
export default jenkins;
