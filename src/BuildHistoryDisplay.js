import React, { Component, Fragment } from 'react';
import jenkins from './Jenkins.js';
import AsOf from './AsOf.js';
import { summarize_date, toYYYYmmdd } from './Summarize.js';
import * as d3 from 'd3v4';
import parse_duration from 'parse-duration';
import Tooltip from 'rc-tooltip';
import axios from 'axios';

const LOG_URL_PREFIX = 'https://download.pytorch.org/nightly_logs/';
const WHEEL_URL_PREFIX = 'https://download.pytorch.org/whl/nightly/';
const WHEEL_NAME_PREFIX = 'torch_nightly-1.0.0.dev';

function logUrlOfJenkinsName(jenkinsName, date) {
    // jenkinsName is of format
    // linux_pip_2.7m_cpu
    // date has to be of format YYYYmmdd
    let parts = jenkinsName.split('_');
    let obj = {
        'os': parts[0],
        'pkgType': parts[1],
        'pyVer': parts[2],
        'cuVer': parts[3]
    };
    return LOG_URL_PREFIX + obj.os + '/' + date + '/' + obj.pkgType + '_' + obj.pyVer + '_' + obj.cuVer + '.log'
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

    let dateToBuilds = {}
    data.builds.map((datebuild) => {
        dateToBuilds[datebuild.timestamp] = datebuild.subBuilds.map((build) => {
            return {
                'date': datebuild.timestamp,
                'logUrl': logUrlOfJenkinsName(build.jobName, toYYYYmmdd(datebuild.timestamp, '_')),
                'result': build.result
            };
        });
    });
    this.setState({'dateToBuilds': dateToBuilds});
	}

  render() {
    console.log('render() this.state is:');
    console.log(this.state);

    function result_icon(result) {
      if (result === 'SUCCESS') return <span role="img" style={{color:"blue"}} aria-label="passed">0</span>;
      if (result === 'FAILURE') return <span role="img" style={{color:"red"}} aria-label="failed">X</span>;
      if (result === 'ABORTED') return <span role="img" style={{color:"gray"}} aria-label="cancelled">.</span>;
      if (result === 'UNKNOWN') return <span role="img" style={{color:"gray"}} aria-label="in progress">?</span>;
      return result;
    }

    const rows = Object.keys(this.state.dateToBuilds).map((date) => {

      const status_cols = this.state.dateToBuilds[date].map((build) => {
        let cell = <a href={build.logUrl}
                  className="icon"
                  target="_blank"
                  alt={build.logUrl}>
                 {result_icon(build.result)}
               </a>;

        return <Tooltip overlay={build.logUrl}
                      mouseLeaveDelay={0}
                      placement="rightTop"
                      destroyTooltipOnHide={true}><td key={'hello'} className="icon-cell" style={{textAlign: "right", fontFamily: "sans-serif", padding: 0}}>{cell}</td></Tooltip>;
      });

      return (
        <tr key={date}>
          <td className="left-cell">{summarize_date(date)}</td>
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
