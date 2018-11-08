export function summarize_job(job) {
  return job.replace(/^pytorch-/, '').replace(/-trigger$/, '').replace(/^private\//, '').replace(/^ccache-cleanup-/, '');
}

export function summarize_date(timestamp) {
  if (typeof(timestamp) == typeof('str')) {
      timestamp = parseInt(timestamp);
  }
  const date = new Date(timestamp);
  const today = new Date();
  if (today.toLocaleDateString() === date.toLocaleDateString()) {
    return date.toLocaleString('en-US', { hour: 'numeric', minute: 'numeric', hour12: true });
  } else {
    return date.toLocaleString('en-US', { month: 'short', day: 'numeric', weekday: 'short' });
  }
}

// https://stackoverflow.com/questions/23593052/format-javascript-date-to-yyyy-mm-dd
export function toYYYYmmdd(timestamp, delimiter) {
    var d = new Date(timestamp);
    var month = '' + (d.getMonth() + 1);
    var day = '' + d.getDate();
    var year = d.getFullYear();

    if (month.length < 2) month = '0' + month;
    if (day.length < 2) day = '0' + day;

    return [year, month, day].join(delimiter);
}

// https://stackoverflow.com/questions/6312993/javascript-seconds-to-time-string-with-format-hhmmss
export function seconds2time (seconds) {
    let hours   = Math.floor(seconds / 3600);
    let minutes = Math.floor((seconds - (hours * 3600)) / 60);
    seconds = seconds - (hours * 3600) - (minutes * 60);
    let time = "";

    if (hours !== 0) {
      time = hours+":";
    }
    if (minutes !== 0 || time !== "") {
      minutes = (minutes < 10 && time !== "") ? "0"+minutes : String(minutes);
      time += minutes+":";
    }
    if (time === "") {
      time = seconds+"s";
    }
    else {
      time += (seconds < 10) ? "0"+seconds : String(seconds);
    }
    return time;
}

export function summarize_ago(timestamp) {
  const date = new Date(timestamp);
  const today = new Date();
  return seconds2time(Math.floor((today - date) / 1000));
}

export function summarize_project(project) {
  return project.replace(/-builds$/, '');
}

export function summarize_url(url) {
  let m;
  if ((m = RegExp('^https://ci\\.pytorch\\.org/jenkins/job/([^/]+)/job/([^/]+)/').exec(url)) !== null) {
    return summarize_project(m[1]) + "/" + summarize_job(m[2]);
  }
  if ((m = RegExp('https://ci\\.pytorch\\.org/jenkins/job/([^/]+)/').exec(url)) !== null) {
    return m[1];
  }
  return url;
}

// Last updated 2018-03-01
export const centsPerHour = {
  'linux-cpu': 17, // c5.xlarge
  'linux-bigcpu': 68, // c5.4xlarge
  'linux-gpu': 228, // g3.8xlarge
  'linux-tc-gpu': 228, // g3.8xlarge
  'linux-multigpu': 456, // g3.16xlarge
  'linux-cpu-ccache': 17, // c5.xlarge
  'win-cpu': 34, // c5.2xlarge
  'win-gpu': 114, // g3.4xlarge
  'osx': 13900/30/24, // MacStadium mini i7 250 elite
  'master': 17, // c5.xlarge
  'packet': 40, // ???? Packet server ???
  'rocm': 0, // we don't pay for it
  'tc-gpu': 114, // g3.4xlarge
};

export function centsToDollars(x) {
  if (x === undefined) return "?";
  // I feel a little dirty resorting to floating point math
  // here...
  return (x / 100).toLocaleString("en-US", {style: "currency", currency: "USD"});
}
