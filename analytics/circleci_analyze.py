#!/usr/bin/env python3.7
from datetime import datetime, time
import json
import requests
import itertools
import sqlite3
import os
import sys
from typing import Optional, List, Dict, Dict

def get_executor_price_rate(executor):
    (etype, eclass) = executor['type'], executor['resource_class']
    assert etype in ['machine', 'docker', 'macos', 'runner'], f'Unexpected type {etype}'
    if etype == 'machine':
        return {
                'medium': 10,
                'large': 20,
                'xlarge': 100,
                '2xlarge': 200,
                'gpu.medium': 160,
                'gpu.large': 320,
                'gpu.small': 80,
                'windows.medium': 40,
                'windows.large': 120,
                'windows.xlarge': 210,
                'windows.2xlarge': 500,
                'windows.gpu.nvidia.medium': 500,
                'gpu.nvidia.small': 160,
                'gpu.nvidia.medium': 240,
                'gpu.nvidia.large': 1000,
                }[eclass]
    if etype == 'macos':
        return {
                'medium': 50,
                'large': 100,
                }[eclass]
    if etype == 'docker':
        return {
                'small': 5,
                'medium': 10,
                'medium+': 15,
                'large': 20,
                'xlarge': 40,
                '2xlarge': 80,
                '2xlarge+': 100,
                }[eclass]
    if etype == 'runner':
        return {
                'pytorch/amd-gpu': 0,
                }[eclass]
    raise RuntimeError(f'Undefined executor {etype}:{eclass}')

price_per_credit = 6e-4


def get_circleci_token() -> str:
    token_file_path = os.path.join(os.getenv('HOME'), '.circleci_token')
    token = os.getenv('CIRCLECI_TOKEN')
    if token is not None: return token
    if not os.path.exists(token_file_path):
        raise RuntimeError('Can not get CirclCI token neither from CIRCLECI_TOKEN environment variable, nor via ~/.circleci_token file')
    with open(token_file_path) as f:
        return f.read().strip()

class CircleCICache:
    def __init__(self, token, db_name='circleci-cache.db'):
        file_folder = os.path.dirname(__file__)
        self.url_prefix = 'https://circleci.com/api/v2'
        self.session = requests.session()
        self.headers = {
                'Accept': 'application/json',
                'Circle-Token': token,
                }
        self.db = sqlite3.connect(os.path.join(file_folder, db_name))
        self.db.execute('CREATE TABLE IF NOT EXISTS jobs(slug TEXT NOT NULL, job_id INTENER NOT NULL, json TEXT NOT NULL);')
        self.db.execute('CREATE UNIQUE INDEX IF NOT EXISTS jobs_key on jobs(slug, job_id);')
        self.db.execute('CREATE TABLE IF NOT EXISTS workflows(id TEXT NOT NULL PRIMARY KEY, json TEXT NOT NULL);')
        self.db.commit()

    def _get_paged_items_list(self, url: str, params = {}, item_count: Optional[int] =-1) -> List:
        rc, token, run_once = [], None, False 
        def _should_quit():
            nonlocal run_once, rc, token
            if not run_once:
                run_once = True
                return False
            if token is None: return True
            if item_count is None: return True
            return item_count >= 0 and len(rc) >= item_count

        while not _should_quit():
            if token is not None: params['page-token'] = token
            r = self.session.get(url, params = params, headers = self.headers)
            j = r.json()
            if 'message' in j:
                raise RuntimeError(f'Failed to get list from {url}: {j["message"]}')
            token = j['next_page_token']
            rc.extend(j['items'])
        return rc

    def get_pipelines(self, project='github/pytorch/pytorch',branch=None, item_count=None) -> List:
        return self._get_paged_items_list( f'{self.url_prefix}/project/{project}/pipeline', {'branch': branch} if branch is not None else {}, item_count)

    def get_pipeline_workflows(self, pipeline) -> List:
        return self._get_paged_items_list(f'{self.url_prefix}/pipeline/{pipeline}/workflow')

    def get_workflow_jobs(self, workflow, should_cache = True) -> List:
        c = self.db.cursor()
        c.execute("select json from workflows where id=?", (workflow,))
        rc = c.fetchone()
        if rc is not None:
            return json.loads(rc[0])
        rc = self._get_paged_items_list(f'{self.url_prefix}/workflow/{workflow}/job')
        if should_cache:
            self.db.execute("INSERT INTO workflows(id, json) VALUES (?, ?)", (workflow, json.dumps(rc)))
            self.db.commit()
        return rc

    def get_job(self, project_slug, job_number) -> Dict:
        c = self.db.cursor()
        c.execute("select json from jobs where slug=? and job_id = ?", (project_slug, job_number))
        rc = c.fetchone()
        if rc is not None:
            return json.loads(rc[0])
        r = self.session.get(f'{self.url_prefix}/project/{project_slug}/job/{job_number}', headers = self.headers)
        rc=r.json()
        self.db.execute("INSERT INTO jobs(slug,job_id, json) VALUES (?, ?, ?)", (project_slug, job_number, json.dumps(rc)))
        self.db.commit()
        return rc


    def get_jobs_summary(self, slug='gh/pytorch/pytorch', workflow='build') -> Dict:
        r = requests.get(f'{self.url_prefix}/insights/{slug}/workflows/{workflow}/jobs', headers = self.headers)
        rc = dict()
        for item in r.json()['items']:
            rc[item['name']] = item
        return rc


    def get_jobs_summary(self, slug='gh/pytorch/pytorch', workflow='build') -> Dict:
        r = requests.get(f'{self.url_prefix}/insights/{slug}/workflows/{workflow}/jobs', headers = self.headers)
        rc = dict()
        for item in r.json()['items']:
            rc[item['name']] = item
        return rc

    def get_job_timeseries(self, job_name, slug='gh/pytorch/pytorch', workflow='build') -> List:
        r = requests.get(f'{self.url_prefix}/insights/{slug}/workflows/build/jobs/{job_name}', headers = self.headers)
        return [(datetime.fromisoformat(x['started_at'][:-1]), x['duration']) for x in r.json()['items'] if x['status'] == 'success']

def aggregate_by_day(series):
    rc = {}
    for (ts, val) in series:
        date = datetime.combine(ts.date(), time())
        valcount = [val, 1.0]
        if date not in rc:
            rc[date] = valcount
        else:
            rc[date] = [sum(x) for x in zip(rc[date], valcount)]
    return [(x, rc[x][0] / rc[x][1]) for x in sorted(rc.keys())]


def plot_graph(name_filter=None):
    import matplotlib.pyplot as plt
    import matplotlib.dates as mdates

    ci_cache = CircleCICache(token=get_circleci_token())
    summary = ci_cache.get_jobs_summary()
    test_jobs = [ name for name in summary.keys() if name.startswith('pytorch') and 'test' in name]
    series = []
    labels = []
    styles = [f'{color}{style}' for (style,color) in itertools.product(['-','--','-.',':'], ['b','g','r','c','m','y','k'])]
    for name in test_jobs:
        label=f"{name}(p95 = {int(summary[name]['metrics']['duration_metrics']['p95']/60)} min)"
        print(label)
        if name_filter is not None and name_filter not in name:
            continue
        ts = ci_cache.get_job_timeseries(name)
        if len(ts) == 0:
            continue
        labels.append(label)
        series.append(ts)
        x,y=zip(*aggregate_by_day(ts))
        plt.plot(x, y, styles[len(labels)%len(styles)])
    plt.legend(labels)
    plt.show()

def print_line(line: str, padding: Optional[int] =None, newline: bool =True) -> None:
    if padding is not None and len(line) < padding:
        line += ' '*(padding - len(line))
    print(line, end = '\n' if newline else '\r', flush=True)

def fetch_status(branch=None, item_count=50):
    isatty = sys.stdout.isatty()
    padding = os.get_terminal_size().columns -1 if isatty else None
    ci_cache = CircleCICache(token=get_circleci_token())
    pipelines = ci_cache.get_pipelines(branch=branch, item_count=item_count)
    total_price, total_master_price = 0, 0
    for pipeline in pipelines:
        revision = pipeline['vcs']['revision']
        branch = pipeline['vcs']['branch']
        workflows = ci_cache.get_pipeline_workflows(pipeline['id'])
        known_job_ids = []
        for workflow in workflows:
            url = f'https://app.circleci.com/pipelines/github/pytorch/pytorch/{workflow["pipeline_number"]}/workflows/{workflow["id"]}'
            if workflow['status'] in ['running', 'not_run', 'failing', 'on_hold']:
                print_line(f'Skipping {url} name:{workflow["name"]} status:{workflow["status"]}', newline=not sys.stdout.isatty())
                continue
            rerun=False
            total_credits, test_credits, gpu_credits, wincpu_credits, wingpu_credits = 0, 0, 0, 0, 0
            jobs = ci_cache.get_workflow_jobs(workflow['id'])
            for job in jobs:
                job_name, job_status, job_number = job['name'], job['status'], job.get('job_number', None)
                if job_status in ['blocked', 'canceled', 'unauthorized', 'running', 'not_run', 'failing']: continue
                if job_number is None:
                    print(job)
                    continue
                if job_number in known_job_ids:
                    rerun = True
                    continue
                job_info = ci_cache.get_job(job['project_slug'], job_number)
                job_executor = job_info['executor']
                resource_class = job_executor['resource_class']
                job_on_gpu = 'gpu' in resource_class
                job_on_win = 'windows' in resource_class
                duration = datetime.fromisoformat(job_info['stopped_at'][:-1]) - datetime.fromisoformat(job_info['started_at'][:-1])
                job_credits = get_executor_price_rate(job_executor) * int(job_info['duration']) * 1e-3 / 60
                job_cost = job_credits * price_per_credit
                total_credits += job_credits
                if 'test' in job_name or job_name.startswith('smoke_'):
                    test_credits += job_credits
                elif job_on_gpu:
                    print(f'Running build job {job_name} on GPU!!!')
                if job_on_gpu:
                    gpu_credits += job_credits
                    if job_on_win: wingpu_credits += job_credits
                if job_on_win and not job_on_gpu:
                    wincpu_credits += job_credits
                known_job_ids.append(job_number)
                print_line(f'         {job_name} {job_status}  {duration} ${job_cost:.2f}', padding = padding, newline = not isatty)
            # Increment totals
            total_price += total_credits * price_per_credit
            if branch in ['master', 'nightly', 'postnightly', 'release/1.6']:
                total_master_price += total_credits * price_per_credit
            # skip small jobs
            if total_credits * price_per_credit < .1: continue
            workflow_status = f'{url} {workflow["name"]} status:{workflow["status"]} price: ${total_credits * price_per_credit:.2f}'
            workflow_status += ' (Rerun?)' if rerun else ''
            workflow_status += f'\n\t\tdate: {workflow["created_at"]} branch:{branch} revision:{revision}'
            workflow_status += f'\n\t\ttotal credits: {int(total_credits)}'
            if test_credits != 0:
                workflow_status += f' testing: {100 * test_credits / total_credits:.1f}%'
            if gpu_credits != 0:
                workflow_status += f' GPU testing: {100 * gpu_credits / total_credits:.1f}%'
                if wingpu_credits != 0:
                    workflow_status += f' WINGPU/GPU: {100 * wingpu_credits / gpu_credits:.1f}%'

            if wincpu_credits != 0:
                workflow_status += f' Win CPU: {100 * wincpu_credits / total_credits:.1f}%'
            workflow_status += f' Total: ${total_price:.2f} master fraction: {100 * total_master_price/ total_price:.1f}%'
            print_line(workflow_status, padding = padding)

if __name__ == '__main__':
    #plot_graph()
    fetch_status(branch='master', item_count=100)
    #fetch_status(None, 2000)
