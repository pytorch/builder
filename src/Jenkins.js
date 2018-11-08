import axios from 'axios';

export class Jenkins {
  url(s) {
    return "https://ci.pytorch.org/jenkins/" + s + "/api/json";
  }
  link(s) {
    return "https://ci.pytorch.org/jenkins/" + s;
  }

  async get(url, options) {
    if (options === undefined) options = {};
    var r;
    await axios.get(url, { params: options })
    .then(response => {
      r = response;
    })
    .catch(error => {
      // console.log("error.response: ", error.response)
    });
    if (typeof r !== 'undefined') {
      return r.data;
    } else {
      return null;
    }
  }

  async computer(options) { return this.get(this.url("computer"), options); }
  async queue(options) { return this.get(this.url("queue"), options); }
  async job(v, options) { return this.get(this.url("job/" + v), options); }
}

const jenkins = new Jenkins();
export default jenkins;
