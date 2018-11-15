export function summarize_job(job) {
  return job.replace(/^pytorch-/, '').replace(/-trigger$/, '').replace(/^private\//, '').replace(/^ccache-cleanup-/, '');
}

export function summarize_date(timestamp) {
  if (typeof(timestamp) === typeof('str')) {
      timestamp = parseInt(timestamp, 10);
  }
  const date = new Date(timestamp);
  const today = new Date();
  if (today.toLocaleDateString() === date.toLocaleDateString()) {
    return date.toLocaleString('en-US', { hour: 'numeric', minute: 'numeric', hour12: true });
  } else {
    return date.toLocaleString('en-US', { month: 'short', day: 'numeric', weekday: 'short' });
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
