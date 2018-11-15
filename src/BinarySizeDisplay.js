import React, { Component } from 'react';
import { allJobNames, get_request, objFromJobName, objFromOsPkgPyCu } from './Utils.js';
import Tooltip from 'rc-tooltip';


function formatBytes(bytes) {
    return Math.round(bytes / 1024 / 1024);
}

export default class BinarySizeDisplay extends Component {
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
    let dates = ['2018_11_15', '2018_11_14', '2018_11_13', '2018_11_12'];
    let dateToBuilds = {};

    dates.map(async (date) => {
        // the 2018_11_14.json contains an array of objects with keys [os, pkg, py, cu, size]
        //let sizeObjs = await get_request('http://download.pytorch.org/nightly_logs/binary_sizes/' + date + '.json');
        let sizeObjs = await get_request('https://s3.amazonaws.com/pytorch/nightly_logs/binary_sizes/' + date + '.json');

        // Convert objs from <date>.json to buildObjs for consistency
        let buildObjs = sizeObjs.map((sizeObj) => {
            return objFromOsPkgPyCu(sizeObj, {'size': sizeObj.size});
        }).sort(function(a, b) {
            return a.jobName > b.jobName ? 1 : -1; 
        });

        // Create a map like {'date': {'jobName': buildObj ... } ... }
        let jobNameToBuildObj = {};
        var i;
        for (i = 0; i < buildObjs.length; ++i) {
            jobNameToBuildObj[buildObjs[i].jobName] = buildObjs[i];
        }

        // Have to set the state within this async map
        dateToBuilds[date] = jobNameToBuildObj;
        this.setState({'dateToBuilds': dateToBuilds});
    });
	}

  render() {

    const rows = Object.keys(this.state.dateToBuilds).sort().reverse().map((yyyy_mm_dd) => {
      let jobNameToBuildObj = this.state.dateToBuilds[yyyy_mm_dd];
      const status_cols = allJobNames.map((jobName) => {
        // If there's not a result for this job (if the build failed) then
        // create a default obj)
        let buildObj = {};
        if (jobName in jobNameToBuildObj) {
          buildObj = jobNameToBuildObj[jobName];
        } else {
          buildObj = objFromJobName(jobName, {'size': -1});
        }

        // The underscore is a hacky way to keep the numbers apart
        let cell = <a href={buildObj.logUrl(yyyy_mm_dd)}
                  target="_blank"
                  >
                  {formatBytes(buildObj.extraParams.size)}_
               </a>;

        return <Tooltip overlay={buildObj.jobName}
                      mouseLeaveDelay={0}
                      placement="rightTop"
                      destroyTooltipOnHide={true}><td key={buildObj.jobName} className="icon-cell" style={{textAlign: "right", fontFamily: "sans-serif", padding: 0}}>{cell}</td></Tooltip>;
      }); // status_cols

      // TODO make this date in the left column pretty
      return (
        <tr key={yyyy_mm_dd}>
          <td className="left-cell">{yyyy_mm_dd}</td>
          {status_cols}
        </tr>
        );
    });

    return (
      <div>
        <h2>
         Binary Sizes
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
