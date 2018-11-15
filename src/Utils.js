import axios from 'axios';

const LOG_URL_PREFIX = 'https://download.pytorch.org/nightly_logs/';
const WHEEL_URL_PREFIX = 'https://download.pytorch.org/whl/nightly/';
const WHEEL_NAME_PREFIX = 'torch_nightly-1.0.0.dev';

// https://stackoverflow.com/questions/23593052/format-javascript-date-to-yyyy-mm-dd
export function toYYYYmmdd(timestamp, delimiter) {
    if (typeof(timestamp) === typeof('str')) {
        timestamp = parseInt(timestamp, 10);
    }
    var d = new Date(timestamp);
    var month = '' + (d.getMonth() + 1);
    var day = '' + d.getDate();
    var year = d.getFullYear();

    if (month.length < 2) month = '0' + month;
    if (day.length < 2) day = '0' + day;

    return [year, month, day].join(delimiter);
}


export function objFromOsPkgPyCu(obj, extraParams) {
    let jobName = [obj.os, obj.pkgType, obj.pyVer, obj.cuVer].join('_');
    let shortName = [obj.pkgType, obj.pyVer, obj.cuVer].join('_');

    return {
        'os': obj.os,
        'pkgType': obj.pkgType,
        'pyVer': obj.pyVer,
        'cuVer': obj.cuVer,
        'jobName': jobName,
        'shortName': shortName,
        'logUrl': function(date) {
            // date has to be of format YYYYmmdd
            return LOG_URL_PREFIX + obj.os + '/' + toYYYYmmdd(date, '_') + '/' + shortName + '.log'
        },
        'extraParams': extraParams,
    };
}

export function objFromJobName(jobName, extraParams) {
    // "jobName" is of format linux_pip_2.7m_cpu
    let parts = jobName.split('_');
    return objFromOsPkgPyCu({
        'os': parts[0],
        'pkgType': parts[1],
        'pyVer': parts[2],
        'cuVer': parts[3],
    }, extraParams);
}

export async function get_request(url, options) {
  if (options === undefined) options = {};
  var r;
  await axios.get(url, { params: options })
  .then(response => {
    r = response;
  })
  .catch(error => {
    console.log("error.response: ", error.response)
  });
  if (typeof r !== 'undefined') {
    return r.data;
  } else {
    return null;
  }
}

export const allJobNames = [
    'linux_conda_2.7_cpu',
    'linux_conda_3.5_cpu',
    'linux_conda_3.6_cpu',
    'linux_conda_3.7_cpu',

    'linux_conda_2.7_cu80',
    'linux_conda_3.5_cu80',
    'linux_conda_3.6_cu80',
    'linux_conda_3.7_cu80',

    'linux_conda_2.7_cu90',
    'linux_conda_3.5_cu90',
    'linux_conda_3.6_cu90',
    'linux_conda_3.7_cu90',

    'linux_conda_2.7_cu92',
    'linux_conda_3.5_cu92',
    'linux_conda_3.6_cu92',
    'linux_conda_3.7_cu92',

    'macos_conda_2.7_cpu',
    'macos_conda_3.5_cpu',
    'macos_conda_3.6_cpu',
    'macos_conda_3.7_cpu',

    'linux_manywheel_2.7m_cpu',
    'linux_manywheel_2.7mu_cpu',
    'linux_manywheel_3.5m_cpu',
    'linux_manywheel_3.6m_cpu',
    'linux_manywheel_3.7m_cpu',

    'linux_manywheel_2.7m_cu80',
    'linux_manywheel_2.7mu_cu80',
    'linux_manywheel_3.5m_cu80',
    'linux_manywheel_3.6m_cu80',
    'linux_manywheel_3.7m_cu80',

    'linux_manywheel_2.7m_cu90',
    'linux_manywheel_2.7mu_cu90',
    'linux_manywheel_3.5m_cu90',
    'linux_manywheel_3.6m_cu90',
    'linux_manywheel_3.7m_cu90',

    'linux_manywheel_2.7m_cu92',
    'linux_manywheel_2.7mu_cu92',
    'linux_manywheel_3.5m_cu92',
    'linux_manywheel_3.6m_cu92',
    'linux_manywheel_3.7m_cu92',

    'macos_wheel_2.7_cpu',
    'macos_wheel_3.5_cpu',
    'macos_wheel_3.6_cpu',
    'macos_wheel_3.7_cpu',

    'linux_libtorch_2.7m_cpu',
    'linux_libtorch_2.7m_cu80',
    'linux_libtorch_2.7m_cu90',
    'linux_libtorch_2.7m_cu92',
    'macos_libtorch_2.7m_cpu',
];
