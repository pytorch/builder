import React, { Component } from 'react';
import { allJobNames, get_request, objFromJobName, objFromOsPkgPyCu } from './Utils.js';
import { toYYYYmmdd } from './Summarize.js';
import Tooltip from 'rc-tooltip';


function formatBytes(bytes) {
    return Math.round(bytes / 1024 / 1024);
}

// 1 am PST (I think?)
const startDate = new Date(Date.UTC(2018, 9, 15, 8, 0, 0));
let allDates = [];


export default class BinarySizeDisplay extends Component {
  constructor(props) {
    super(props);
    this.state = this.initialState();
  }

  initialState() {
    // Fill out all the dates
    const today = new Date();
    for (var d = startDate; d <= today; d.setDate(d.getDate() + 1)) {
        allDates.push(new Date(d));
    }
    return {'dateToBuilds': {}};
  }

  componentDidMount() {
    this.setState(this.initialState());
    this.update();
  }

  componentDidUpdate(prevProps) { }

  async update() { 
    let dateToBuilds = {};

    allDates.map(async (date) => {
    //[].map(async (date)  => {
        let date_underscore = toYYYYmmdd(date, '_');
        // the 2018_11_14.json contains an array of objects with keys [os, pkg, py, cu, size]
        let sizeObjs = await get_request('https://s3.amazonaws.com/pytorch/nightly_logs/binary_sizes/' + date_underscore + '.json');

        // Convert objs from <date_underscore>.json to buildObjs for consistency
        let buildObjs = sizeObjs.map((sizeObj) => {
            return objFromOsPkgPyCu(sizeObj, {'size': sizeObj.size});
        }).sort(function(a, b) {
            return a.jobName > b.jobName ? 1 : -1; 
        });

        // Create a map like {'date_underscore': {'jobName': buildObj ... } ... }
        let jobNameToBuildObj = {};
        var i;
        for (i = 0; i < buildObjs.length; ++i) {
            jobNameToBuildObj[buildObjs[i].jobName] = buildObjs[i];
        }

        // Have to set the state within this async map
        dateToBuilds[date_underscore] = jobNameToBuildObj;
        this.setState({'dateToBuilds': dateToBuilds});
    });
	}

  render() {

    const rows = allDates.reverse().map((date) => {
      let yyyy_mm_dd = toYYYYmmdd(date, '_');

      // This date may not be populated yet, if not then leave it blank
      var status_cols;
      if (yyyy_mm_dd in this.state.dateToBuilds) {
      let jobNameToBuildObj = this.state.dateToBuilds[yyyy_mm_dd];
          status_cols = allJobNames.map((jobName) => {
            // If there's not a result for this job (if the build failed) then
            // create a default obj)
            let buildObj = {};
            if (jobName in jobNameToBuildObj) {
              buildObj = jobNameToBuildObj[jobName];
            } else {
              buildObj = objFromJobName(jobName, {'size': -1});
            }

            let cell = <a href={buildObj.logUrl(yyyy_mm_dd)}
                      className="icon"
                      target="_blank"
                      >
                      &nbsp;{formatBytes(buildObj.extraParams.size)}&nbsp;
                   </a>;

            return <Tooltip overlay={buildObj.jobName}
                          mouseLeaveDelay={0}
                          placement="rightTop"
                          destroyTooltipOnHide={true}><td key={buildObj.jobName} className="icon-cell" style={{textAlign: "right", fontFamily: "sans-serif", padding: 0}}>{cell}</td></Tooltip>;
          });
      } else {
          status_cols = [];
      } // status_cols

      // This does not use Summarize.js::summarize_date because we want the
      // date for the current day too
      return (
        <tr key={date}>
          <td className="left-cell">{date.toLocaleString('en-US', { month: 'short', day: 'numeric', weekday: 'short' })}</td>
          {status_cols}
        </tr>
        );
    }); // rows

    return (
      <div>
        <h2>
         Binary Sizes
        </h2>
        <table className="buildHistoryTable">
          <thead>
            <tr>
              <th className="left-cell">Date</th>
              {allJobNames.map((job) => { return <th className="rotate" ><div>{job}</div></th>; })}
            </tr>
          </thead>
          <tbody>{rows}</tbody>
        </table>
      </div>
    );
  }
}
