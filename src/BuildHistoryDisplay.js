import React, { Component } from 'react';
import jenkins from './Jenkins.js';
import { summarize_date } from './Summarize.js';
import { allJobNames, objFromJobName } from './Utils.js';
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

        // Create a map like {'jobName': buildObj ... }
        let jobNameToBuildObj = {};
        var build_idx;
        for (build_idx = 0; build_idx < datebuild.subBuilds.length; ++build_idx) {
            let build = datebuild.subBuilds[build_idx];
            let buildObj = objFromJobName(build.jobName, {
                'timestamp': datebuild.timestamp,
                'result': build.result
            });
            jobNameToBuildObj[buildObj.jobName] = buildObj;
        };

        // Create a map like {'date': {'jobName': buildObj ... } ... }
        dateToBuilds[datebuild.timestamp] = jobNameToBuildObj;
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
      let jobNameToBuildObj = this.state.dateToBuilds[timestamp];

      const status_cols = allJobNames.map((jobName) => {
        // If there's not a result for this job (if the build failed) then
        // create a default obj)
        let buildObj = {};
        if (jobName in jobNameToBuildObj) {
          buildObj = jobNameToBuildObj[jobName];
        } else {
          buildObj = objFromJobName(jobName, {'timestamp': timestamp, 'result': 'UNKNOWN'});
        }

        let cell = <a href={buildObj.logUrl(timestamp)}
                  className="icon"
                  target="_blank"
                  alt={buildObj.logUrl(timestamp)}>
                 &nbsp;{result_icon(buildObj.extraParams.result)}&nbsp;
               </a>;

        return <Tooltip overlay={buildObj.jobName}
                      mouseLeaveDelay={0}
                      placement="rightTop"
                      destroyTooltipOnHide={true}><td key={buildObj.name} className="icon-cell" style={{textAlign: "right", fontFamily: "sans-serif", padding: 0}}>{cell}</td></Tooltip>;
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
              {allJobNames.map((job) => { return <th class="rotate" ><div>{job}</div></th>; })}
            </tr>
          </thead>
          <tbody>{rows}</tbody>
        </table>
      </div>
    );
  }
}
