import React, { Component } from 'react';
import jenkins from './Jenkins.js';
import { summarize_date } from './Summarize.js';
import { objFromJobName } from './Utils.js';
import Tooltip from 'rc-tooltip';


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

    // {'date': [jenkinsBuildObj...] ...}
    let dateToBuilds = {}
    var i;
    for (i = 0; i < data.builds.length; ++i) {
        let datebuild = data.builds[i];
        dateToBuilds[datebuild.timestamp] = datebuild.subBuilds.map((build) => {
            return objFromJobName(build.jobName, {
                'timestamp': datebuild.timestamp,
                'result': build.result
            });
        }).sort(function(a, b) {
            return a.name > b.name ? 1 : -1; 
        });
    }
    this.setState({'dateToBuilds': dateToBuilds});
	}

  render() {

    function result_icon(result) {
      if (result === 'SUCCESS') return <span role="img" style={{color:"blue"}} aria-label="passed">0</span>;
      if (result === 'FAILURE') return <span role="img" style={{color:"red"}} aria-label="failed">X</span>;
      if (result === 'ABORTED') return <span role="img" style={{color:"gray"}} aria-label="cancelled">.</span>;
      if (result === 'UNKNOWN') return <span role="img" style={{color:"gray"}} aria-label="in progress">?</span>;
      return result;
    }

    const rows = Object.keys(this.state.dateToBuilds).map((timestamp) => {

      const status_cols = this.state.dateToBuilds[timestamp].map((build) => {
        let cell = <a href={build.logUrl}
                  className="icon"
                  target="_blank"
                  alt={build.logUrl(timestamp)}>
                 {result_icon(build.extraParams.result)}
               </a>;

        return <Tooltip overlay={build.logUrl(timestamp)}
                      mouseLeaveDelay={0}
                      placement="rightTop"
                      destroyTooltipOnHide={true}><td key={build.name} className="icon-cell" style={{textAlign: "right", fontFamily: "sans-serif", padding: 0}}>{cell}</td></Tooltip>;
      });

      return (
        <tr key={timestamp}>
          <td className="left-cell">{summarize_date(timestamp)}</td>
          {status_cols}
        </tr>
        );
    });

    return (
      <div>
        <h2>
         Build Success/Failures
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
