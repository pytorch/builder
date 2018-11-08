import React, { Component, Fragment } from 'react';
import jenkins from './Jenkins.js';
import AsOf from './AsOf.js';
import { summarize_date, centsToDollars, centsPerHour } from './Summarize.js';
import * as d3 from 'd3v4';
import parse_duration from 'parse-duration';
import Tooltip from 'rc-tooltip';
import axios from 'axios';

const LOG_URL_PREFIX = 'https://download.pytorch.org/nightly_logs/';
const WHEEL_URL_PREFIX = 'https://download.pytorch.org/whl/nightly/';
const WHEEL_NAME_PREFIX = 'torch_nightly-1.0.0.dev';

function logUrlOfJenkinsName(jenkinsName) {
    // jenkinsName is of format
    // linux_pip_2.7m_cpu
    let parts = jenkinsName.split('_');
    let obj = {
        'os': parts[0],
        'pkgType': parts[1],
        'pyVer': parts[2],
        'cuVer': parts[3]
    };
    return LOG_URL_PREFIX + obj.os + '/' + '2018_11_07' + '/' + obj.pkgType + '_' + obj.pyVer + '_' + obj.cuVer + '.log'
}

function getAllBuilds() {
  const allBuilds = [];

  // Add all Mac builds
  for (const pkgType of ['conda', 'wheel']) {
    for (const pyVer of ['2.7', '3.5', '3.6', '3.7']) {
      const build = {};
      build.os = 'mac';
      build.pkgType = pkgType;
      build.cuVer = 'cpu';
      build.shortPyVer = pyVer;
      if (pkgType === 'wheel') {
        build.longPyVer = 'cp' + pyVer.charAt(0) + pyVer.charAt(2) + '-none';
        // param date = '20181106'
        build.binaryUrl = function(date) { return WHEEL_URL_PREFIX + 'cpu/' + WHEEL_NAME_PREFIX + date + '-' + build.longPyVer + '-macosx_10_6_x86_64.whl'; };
      } else {
        build.longPyVer = pyVer;
        build.binaryUrl = function(date) { return 'TODO'; };
      }
      // param date = '2018_11_06'
      build.logUrl = function(date) { return LOG_URL_PREFIX + 'mac/' + date + '/' + pkgType + '_' + pyVer + '_' + 'cpu.log'; };
      allBuilds.push(build);
    }
  }

  // Add all Linux builds
  for (const pkgType of ['conda', 'manywheel']) {
    let pyVersions = ['2.7', '3.5', '3.6', '3.7'];
    if (pkgType === 'manywheel') {
      pyVersions = ['2.7m', '2.7mu', '3.5m', '3.6m', '3.7m'];
    }
    for (const pyVer of pyVersions) {
      for (const cuVer of ['cpu', 'cu80', 'cu90', 'cu92']) {
        const build = {};
        build.os = 'linux';
        build.pkgType = pkgType;
        build.cuVer = cuVer;
        build.shortPyVer = pyVer;
        if (pkgType === 'manywheel') {
          build.longPyVer = 'cp' + pyVer.charAt(0) + pyVer.charAt(2) + '-cp' + pyVer.charAt(0) + pyVer.substring(2);
          // param date = '20181106'
          build.binaryUrl = function(date) { return WHEEL_URL_PREFIX + cuVer + '/' + WHEEL_NAME_PREFIX + date + '-' + build.longPyVer + '-macosx_10_6_x86_64.whl'; };
        } else {
          build.longPyVer = pyVer;
          build.binaryUrl = function(date) { return 'TODO'; };
        }
        // param date = '2018_11_06'
        build.logUrl = function(date) { return LOG_URL_PREFIX + 'linux/' + date + '/' + pkgType + '_' + pyVer + '_' + cuVer + '.log'; };
        allBuilds.push(build);
      }
    }
  }
  return allBuilds;
}

async function get(url, options) {
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


export default class BuildHistoryDisplay extends Component {
  constructor(props) {
    super(props);
    this.state = this.initialState();
  }

  initialState() {
    return {'dateToBuilds': {}};
  }

  componentDidMount() {
    this.setState(this.initialState());
    this.update();
  }

  componentDidUpdate(prevProps) { }

  async update() { 
    let data = await jenkins.job('nightlies-uploaded',
            {tree: `builds[
                      timestamp,
                      number,
                      subBuilds[
                        result,jobName,url,duration,
                        build[
                          subBuilds[
                            result,jobName,url,duration,
                            build[
                              subBuilds[result,jobName,url,duration]
                            ]
                          ]
                        ]
                      ]
                   ]`.replace(/\s+/g, '')});

    let dateToBuilds = {};
    data.builds.map((datebuild) => {
        const whenString = summarize_date(datebuild.timestamp);
        dateToBuilds[whenString] = datebuild.subBuilds.map((build) => {
            return {
                'logUrl': logUrlOfJenkinsName(build.jobName),
                'result': build.result
            }
        });
    });
    console.log(dateToBuilds);
    this.setState({'dateToBuilds': dateToBuilds});
	}

  render() {
    console.log(this.state);

    function result_icon(result) {
      if (result === 'SUCCESS') return <span role="img" style={{color:"blue"}} aria-label="passed">0</span>;
      if (result === 'FAILURE') return <span role="img" style={{color:"red"}} aria-label="failed">X</span>;
      if (result === 'ABORTED') return <span role="img" style={{color:"gray"}} aria-label="cancelled">.</span>;
      if (result === 'UNKNOWN') return <span role="img" style={{color:"gray"}} aria-label="in progress">?</span>;
      return result;
    }

    const rows = Object.keys(this.state.dateToBuilds).map((date) => {

      const status_cols = this.state.dateToBuilds[date].map((buildResult) => {
        let cell = <a href={buildResult.logUrl}
                  className="icon"
                  target="_blank"
                  alt={buildResult.logUrl}>
                 {result_icon(buildResult.result)}
               </a>;

        return <Tooltip overlay={buildResult.logUrl}
                      mouseLeaveDelay={0}
                      placement="rightTop"
                      destroyTooltipOnHide={true}><td key={'hello'} className="icon-cell" style={{textAlign: "right", fontFamily: "sans-serif", padding: 0}}>{cell}</td></Tooltip>;
      });

      return (
        <tr key={date}>
          <td className="left-cell">{date}</td>
          {status_cols}
        </tr>
        );
    });

    return (
      <div>
        <h2>
         Heading
        </h2>
        <table className="buildHistoryTable">
          <thead>
            <tr>
              <th className="left-cell">Date</th>
              <th>Status</th>
            </tr>
          </thead>
          <tbody>{rows}</tbody>
        </table>
      </div>
    );
  }
}
