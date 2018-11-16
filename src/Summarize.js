export function summarize_job(job) {
  return job.replace(/^pytorch-/, '').replace(/-trigger$/, '').replace(/^private\//, '').replace(/^ccache-cleanup-/, '');
}

export function summarize_date(date) {
  // If a string, assume that it's a timestamp (seconds from epoc)
  if (typeof(date) === typeof('str')) {
      date = parseInt(date, 10);
  }
  var d;
  // If an int, assume that it's a timestamp
  if (typeof(date) === typeof(5)) {
      d = new Date(date);
  } else {
      d = date;
  }
  const today = new Date();
  if (today.toLocaleDateString() === d.toLocaleDateString()) {
    return d.toLocaleString('en-US', { hour: 'numeric', minute: 'numeric', hour12: true });
  } else {
    return d.toLocaleString('en-US', { month: 'short', day: 'numeric', weekday: 'short' });
  }
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

// https://stackoverflow.com/questions/23593052/format-javascript-date-to-yyyy-mm-dd
export function toYYYYmmdd(date, delimiter) {
    // If a string, assume that it's a timestamp (seconds from epoc)
    if (typeof(date) === typeof('str')) {
        date = parseInt(date, 10);
    }
    var d;
    // If an int, assume that it's a timestamp
    if (typeof(date) === typeof(5)) {
        d = new Date(date);
    } else {
        d = date;
    }

    var month = '' + (d.getUTCMonth() + 1);
    var day = '' + d.getUTCDate();
    var year = d.getUTCFullYear();

    if (month.length < 2) month = '0' + month;
    if (day.length < 2) day = '0' + day;

    return [year, month, day].join(delimiter);
}
