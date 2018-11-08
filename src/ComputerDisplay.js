import React, { Component } from 'react';
import jenkins from './Jenkins.js';
import AsOf from './AsOf.js';
import { seconds2time, summarize_ago, summarize_url, centsToDollars, centsPerHour } from './Summarize.js';

export default class ComputerDisplay extends Component {
  constructor(props) {
    super(props);
    this.state = { computer: [], currentTime: new Date(), updateTime: new Date(0), connectedIn: 0 };
  }
  componentDidMount() {
    this.update();
    this.interval = setInterval(this.update.bind(this), this.props.interval);
  }
  componentWillUnmount() {
    clearInterval(this.interval);
  }
  async update() {
    const currentTime = new Date();
    this.setState({currentTime: currentTime});
    const data = await jenkins.computer(
      {tree: `computer[
                offline,
                idle,
                displayName,
                assignedLabels[name],
                executors[
                  currentExecutable[
                    timestamp,
                    estimatedDuration,
                    url,
                    building
                  ],
                  idle
                ]
              ]`.replace(/\s+/g, '')});
    data.updateTime = new Date();
    data.connectedIn = data.updateTime - currentTime;
    this.setState(data);
  }
  render() {
    function classify_node(n) {
      const node = n.displayName;
      if (/^c5.xlarge-i-.*$/.test(node)) {
        return 'linux-cpu';
      }
      if (/^c5.4xlarge-i-.*$/.test(node)) {
        return 'linux-bigcpu';
      }
      if (/^g3.8xlarge-i-.*$/.test(node)) {
        if (n.assignedLabels.some((l) => l.name === "tc_gpu")) {
          return 'linux-tc-gpu';
        } else {
          return 'linux-gpu';
        }
      }
      if (/^g3.16xlarge-i-.*$/.test(node)) {
        return 'linux-multigpu';
      }
      if (/^worker-c5-xlarge-.*$/.test(node)) {
        return 'linux-cpu-ccache';
      }
      if (/^worker-macos-high-sierra-.*$/.test(node)) {
        return 'osx';
      }
      if (/^worker-win-c5.2xlarge-i-.*$/.test(node)) {
        return 'win-cpu';
      }
      if (/^worker-win-g3.4xlarge-i-.*$/.test(node)) {
        return 'win-gpu';
      }
      if (/^worker-osuosl-ppc64le-cpu-.*$/.test(node)) {
        return 'ppc';
      }
      if (/^worker-packet-type-1-.*$/.test(node)) {
        return 'packet';
      }
      if (/^jenkins-worker-rocm-.*$/.test(node)) {
        return 'rocm';
      }
      if (/^worker-g3-4xlarge-.*$/.test(node)) {
        return 'tc-gpu';
      }
      return node;
    }

    const map = new Map();
    this.state.computer.forEach((c) => {
      const k = classify_node(c);
      let v = map.get(k);
      if (v === undefined) v = { busy: 0, total: 0 };
      if (!c.offline) {
        v.total++;
        if (!c.idle) v.busy++;
      }
      map.set(k, v);
    });

    let totalCost = 0;
    map.forEach((v, k) => {
      const perCost = centsPerHour[k];
      if (perCost !== undefined) {
        v.totalCost = perCost * v.total;
        totalCost += v.totalCost;
      }
    });

    const rows = [...map.entries()].sort().map(kv => {
      const cost = centsToDollars(kv[1].totalCost);
      return (<tr key={kv[0]}>
          <th>{kv[0]}</th>
          <td>{kv[1].busy} / {kv[1].total}</td>
          <td className="ralign">{cost}/hr</td>
        </tr>);
    });

    const busy_nodes = this.state.computer.filter((c) => !c.idle && c.displayName !== "master" && c.executors.length > 0 && c.executors[0].currentExecutable);
    busy_nodes.sort((a, b) => a.executors[0].currentExecutable.timestamp - b.executors[0].currentExecutable.timestamp);
    const running_rows = busy_nodes.map((c) => {
      const executable = c.executors[0].currentExecutable;
      return <tr key={c.displayName}>
                <td className="left-cell">{summarize_ago(executable.timestamp)}</td>
                <td>
                  <a href={executable.url}>
                    {summarize_url(executable.url)}
                  </a>
                </td>
              </tr>;
    });

    const running_map = new Map();
    busy_nodes.forEach((c) => {
      const executable = c.executors[0].currentExecutable;
      const task = summarize_url(executable.url);
      let v = running_map.get(task);
      if (v === undefined) {
        v = { total: 0, cumulative_time: 0 };
        running_map.set(task, v);
      }
      v.total++;

      function delta_ago(timestamp) {
        const date = new Date(timestamp);
        const today = new Date();
        return (today - date) / 1000;
      }
      v.cumulative_time += delta_ago(executable.timestamp);
    });

    const running_summary = [...running_map.entries()].sort((a, b) => b[1].total - a[1].total).map(task_v => {
      const task = task_v[0];
      const v = task_v[1];
      return <tr key={task}><td style={{textAlign: "right", paddingRight: 15}}>{v.total}</td><th>{task}</th></tr>
    });

    const cumulative_running_time_summary = [...running_map.entries()].sort((a, b) => b[1].cumulative_time - a[1].cumulative_time).map(task_v => {
      const task = task_v[0];
      const v = task_v[1];
      return <tr key={task}><td style={{textAlign: "right", paddingRight: 15}}>{seconds2time(Math.floor(v.cumulative_time))}</td><th>{task}</th></tr>
    });

    return (
      <div>
        <h2>Computers <AsOf interval={this.props.interval} currentTime={this.state.currentTime} updateTime={this.state.updateTime} connectedIn={this.state.connectedIn} /></h2>
        <table>
          <tbody>
            <tr>
              <td>
                <table>
                  <tbody>{rows}</tbody>
                  <tfoot>
                    <tr><td></td><td className="ralign" colSpan="2">{centsToDollars(totalCost*24*30)}/mo</td></tr>
                  </tfoot>
                </table>
              </td>
              <td className="right-cell">
                <table>
                  <tbody>
                    {running_rows}
                  </tbody>
                </table>
              </td>
              { /*
              <td className="right-cell">
                <table>
                  <tbody>
                    {running_summary}
                  </tbody>
                </table>
              </td>
              <td className="right-cell">
                <table>
                  <tbody>
                    {cumulative_running_time_summary}
                  </tbody>
                </table>
              </td>
              */ }
            </tr>
          </tbody>
        </table>
      </div>
      );
  }
}

