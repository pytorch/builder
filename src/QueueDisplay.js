import React, { Component } from 'react';
import jenkins from './Jenkins.js';
import AsOf from './AsOf.js';
import { summarize_url } from './Summarize.js';

export default class QueueDisplay extends Component {
  constructor(props) {
    super(props);
    this.state = { items: [], currentTime: new Date(), updateTime: new Date(0), connectedIn: 0 };
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
    const data = await jenkins.queue();
    data.updateTime = new Date();
    data.connectedIn = data.updateTime - currentTime;
    this.setState(data);
  }
  render() {
    function summarize_why(why) {
      return why.replace(/^Waiting for next available executor on/, 'Needs')
                .replace(/docker&&cpu&&ccache/, 'linux-cpu-ccache')
                .replace(/[^ ]+cpu_ccache.+/, 'linux-cpu-ccache')
                .replace(/docker&&cpu&&!ccache/, 'linux-cpu')
                .replace(/docker&&cpu/, 'linux-cpu-any')
                .replace(/docker&&gpu/, 'linux-gpu')
                .replace(/docker&&bigcpu/, 'linux-bigcpu')
                .replace(/windows&&cpu/, 'windows-cpu')
                .replace(/windows&&gpu/, 'windows-gpu')
                .replace(/g3.8xlarge-i-[^ ]+/, 'linux-gpu')
                .replace(/g3.16xlarge-i-[^ ]+/, 'linux-multigpu')
                .replace(/worker-win-c5.2xlarge-i-[^ ]+/, 'windows-cpu')
                .replace(/worker-win-g3.4xlarge-i-[^ ]+/, 'windows-gpu')
    }

    const why_map = new Map();
    this.state.items.forEach((q) => {
      const why = summarize_why(q.why);
      let v = why_map.get(why);
      if (v === undefined) {
        v = { total: 0 };
        why_map.set(why, v);
      }
      v.total++;
    });

    const why_rows = [...why_map.entries()].sort().map(why_v => {
      const why = why_v[0];
      const v = why_v[1];
      return <tr key={why}><td style={{textAlign: "right", paddingRight: 15}}>{v.total}</td><th>{why}</th></tr>
    });

    const task_map = new Map();
    this.state.items.forEach((q) => {
      const task = summarize_url(q.task.url);
      let v = task_map.get(task);
      if (v === undefined) {
        v = { total: 0 };
        task_map.set(task, v);
      }
      v.total++;
    });

    const task_map_max = 10;
    const task_rows = [...task_map.entries()].sort((a, b) => b[1].total - a[1].total).slice(0, task_map_max).map(task_v => {
      const task = task_v[0];
      const v = task_v[1];
      return <tr key={task}><td style={{textAlign: "right", paddingRight: 15}}>{v.total}</td><th>{task}</th></tr>
    });

    return (
      <div>
        <h2>Queue <AsOf interval={this.props.interval}
                        connectedIn={this.state.connectedIn}
                        currentTime={this.state.currentTime}
                        updateTime={this.state.updateTime} /></h2>
        <table>
          <tbody>
            <tr>
              <td width={300} style={{textOverflow: "clip", maxWidth: 300, overflow: "hidden"}}>
                <table>
                  <tbody>{why_rows}</tbody>
                </table>
              </td>
              <td className="right-cell" width={300}>
                <table>
                  <tbody>{task_rows}<tr><td></td><th>{ task_map.size > task_map_max ? "..." : "" }</th></tr></tbody>
                </table>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    );
  }
}

