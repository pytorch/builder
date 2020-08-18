#!/usr/bin/env python3.7
from datetime import datetime, time
import json
import requests
import itertools
import sqlite3
import os
import sys
from typing import Callable, Dict, List, MutableSet, Optional

def get_executor_price_rate(executor):
    (etype, eclass) = executor['type'], executor['resource_class']
    assert etype in ['machine', 'external', 'docker', 'macos', 'runner'], f'Unexpected type {etype}:{eclass}'
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
    if etype == 'runner' or etype == 'external':
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

def is_workflow_in_progress(workflow: Dict) -> bool:
    return workflow['status'] in ['running', 'not_run', 'failing', 'on_hold']

class CircleCICache:
    def __init__(self, token: Optional[str], db_name: str = 'circleci-cache.db') -> None:
        file_folder = os.path.dirname(__file__)
        self.url_prefix = 'https://circleci.com/api/v2'
        self.session = requests.session()
        self.headers = {
                'Accept': 'application/json',
                'Circle-Token': token,
                } if token is not None else None
        self.db = sqlite3.connect(os.path.join(file_folder, db_name))
        self.db.execute('CREATE TABLE IF NOT EXISTS jobs(slug TEXT NOT NULL, job_id INTENER NOT NULL, json TEXT NOT NULL);')
        self.db.execute('CREATE UNIQUE INDEX IF NOT EXISTS jobs_key on jobs(slug, job_id);')
        self.db.execute('CREATE TABLE IF NOT EXISTS workflows(id TEXT NOT NULL PRIMARY KEY, json TEXT NOT NULL);')
        self.db.execute('CREATE TABLE IF NOT EXISTS pipeline_workflows(id TEXT NOT NULL PRIMARY KEY, json TEXT NOT NULL);')
        self.db.execute('CREATE TABLE IF NOT EXISTS pipelines(id TEXT NOT NULL PRIMARY KEY, json TEXT NOT NULL, branch TEXT, revision TEXT);')
        self.db.commit()

    def is_offline(self) -> bool:
        return self.headers is None

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

    def get_pipelines(self, project: str = 'github/pytorch/pytorch',branch: Optional[str] = None, item_count: Optional[int] = None) -> List:
        if self.is_offline():
            c = self.db.cursor()
            cmd = "SELECT json from pipelines"
            if branch is not None:
                cmd += f" WHERE branch='{branch}'"
            if item_count is not None and item_count > 0:
                cmd += f" LIMIT {item_count}"
            c.execute(cmd)
            return [json.loads(val[0]) for val in c.fetchall()]
        rc = self._get_paged_items_list( f'{self.url_prefix}/project/{project}/pipeline', {'branch': branch} if branch is not None else {}, item_count)
        for pipeline in rc:
            vcs = pipeline['vcs']
            pid, branch, revision, pser = pipeline['id'], vcs['branch'], vcs['revision'], json.dumps(pipeline)
            self.db.execute("INSERT OR REPLACE INTO pipelines(id, branch, revision, json) VALUES (?, ?, ?, ?)", (pid, branch, revision, pser))
        self.db.commit()
        return rc

    def get_pipeline_workflows(self, pipeline) -> List:
        c = self.db.cursor()
        c.execute("SELECT json FROM pipeline_workflows WHERE id=?", (pipeline,))
        rc = c.fetchone()
        if rc is not None:
            rc = json.loads(rc[0])
            if not any([is_workflow_in_progress(w) for w in rc]) or self.is_offline():
                return rc
        if self.is_offline():
            return []
        rc = self._get_paged_items_list(f'{self.url_prefix}/pipeline/{pipeline}/workflow')
        self.db.execute("INSERT OR REPLACE INTO pipeline_workflows(id, json) VALUES (?, ?)", (pipeline, json.dumps(rc)))
        self.db.commit()
        return rc

    def get_workflow_jobs(self, workflow, should_cache = True) -> List:
        c = self.db.cursor()
        c.execute("select json from workflows where id=?", (workflow,))
        rc = c.fetchone()
        if rc is not None:
            return json.loads(rc[0])
        if self.is_offline():
            return []
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
        if self.is_offline():
            return {}
        r = self.session.get(f'{self.url_prefix}/project/{project_slug}/job/{job_number}', headers = self.headers)
        try:
            rc=r.json()
        except json.JSONDecodeError:
            print(f"Failed to decode {rc}", file=sys.stderr)
            raise
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
    print(f"About to fetch {item_count} latest pipelines against {branch if branch is not None else 'all branches'}")
    pipelines = ci_cache.get_pipelines(branch=branch, item_count=item_count)
    total_price, total_master_price = 0, 0
    for pipeline in pipelines:
        revision = pipeline['vcs']['revision']
        branch = pipeline['vcs']['branch']
        workflows = ci_cache.get_pipeline_workflows(pipeline['id'])
        known_job_ids = []
        for workflow in workflows:
            url = f'https://app.circleci.com/pipelines/github/pytorch/pytorch/{workflow["pipeline_number"]}/workflows/{workflow["id"]}'
            if is_workflow_in_progress(workflow):
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
                if 'executor' not in job_info:
                    print(f'executor not found in {job_info}')
                    continue
                job_executor = job_info['executor']
                resource_class = job_executor['resource_class']
                if resource_class is None:
                    print(f'resource_class is none for {job_info}')
                    continue
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


def plot_heatmap(cov_matrix, names):
    import numpy as np
    import matplotlib.pyplot as plt
    assert cov_matrix.shape == (len(names), len(names))
    fig, ax = plt.subplots()
    im = ax.imshow(cov_matrix)
    ax.set_xticks(np.arange(len(names)))
    ax.set_yticks(np.arange(len(names)))
    ax.set_xticklabels(names)
    ax.set_yticklabels(names)
    #Rotate tick labels
    plt.setp(ax.get_xticklabels(), rotation=45, ha='right', rotation_mode='anchor')
    # Annotate values
    for i in range(len(names)):
        for j in range(len(names)):
            ax.text(j, i, f'{cov_matrix[i, j]:.2f}', ha = 'center', va = 'center', color = 'w')
    plt.show()

def filter_service_jobs(name):
    if name.startswith('docker'):
        return True
    if name.startswith('binary'):
        return True
    return False

def filter_cuda_test(name):
    if filter_service_jobs(name):
        return False
    if 'libtorch' in name:
        return False
    if 'test' not in name:
        return False
    # Skip jit-profiling tests
    if 'jit-profiling' in name:
        return False
    if 'cuda11' in name:
        return False
    # Skip VS2017 tests
    if 'vs2017' in name:
        return False
    return 'cuda' in name and 'nogpu' not in name

def filter_cuda_build(name):
    if filter_service_jobs(name):
        return False
    if 'libtorch' in name:
        return False
    return 'cuda' in name and name.endswith('build')

def filter_windows_test(name):
    if filter_service_jobs(name):
        return False
    # Skip jit-profiling tests
    if 'jit-profiling' in name:
        return False
    return 'test' in name and 'windows' in name

def compute_covariance(branch='master', name_filter: Optional[Callable[[str], bool]] = None):
    import numpy as np
    revisions: MutableSet[str] = set()
    job_summary: Dict[str, Dict[str, float]] = {}

    # Extract data
    print(f"Computing covariance for {branch if branch is not None else 'all branches'}")
    ci_cache = CircleCICache(None)
    pipelines = ci_cache.get_pipelines(branch = branch)
    for pipeline in pipelines:
        if pipeline['trigger']['type'] == 'schedule':
            continue
        revision = pipeline['vcs']['revision']
        pipeline_jobs: Dict[str, float] = {}
        blocked_jobs: MutableSet[str] = set()
        workflows = ci_cache.get_pipeline_workflows(pipeline['id'])
        for workflow in workflows:
            if is_workflow_in_progress(workflow):
                continue
            jobs = ci_cache.get_workflow_jobs(workflow['id'])
            for job in jobs:
                job_name = job['name']
                job_status = job['status']
                # Handle renames
                if job_name == 'pytorch_linux_xenial_cuda10_1_cudnn7_py3_NO_AVX2_test':
                    job_name = 'pytorch_linux_xenial_cuda10_1_cudnn7_py3_nogpu_NO_AVX2_test'
                if job_name == 'pytorch_linux_xenial_cuda10_1_cudnn7_py3_NO_AVX_NO_AVX2_test':
                    job_name = 'pytorch_linux_xenial_cuda10_1_cudnn7_py3_nogpu_NO_AVX_test'
                if job_status in ['infrastructure_fail', 'canceled']:
                    continue
                if callable(name_filter) and not name_filter(job_name):
                    continue
                if job_status == 'blocked':
                    blocked_jobs.add(job_name)
                    continue
                if job_name in blocked_jobs:
                    blocked_jobs.remove(job_name)
                result = 1.0 if job_status == 'success' else -1.0
                pipeline_jobs[job_name] = result
        # Skip build with blocked job [which usually means build failed due to the test failure]
        if len(blocked_jobs) != 0:
            continue
        # Skip all success workflows
        if all([result == 1.0 for result in pipeline_jobs.values()]):
         continue
        revisions.add(revision)
        for job_name in pipeline_jobs:
            if job_name not in job_summary:
                job_summary[job_name] = {}
            job_summary[job_name][revision] = pipeline_jobs[job_name]
    # Analyze results
    job_names = sorted(job_summary.keys())
    #revisions = sorted(revisions)
    job_data = np.zeros((len(job_names), len(revisions)), dtype=np.float)
    print(f"Number of observations: {len(revisions)}")
    for job_idx, job_name in enumerate(job_names):
        job_row = job_summary[job_name]
        for rev_idx, revision in enumerate(revisions):
            if revision in job_row:
                job_data[job_idx, rev_idx] = job_row[revision]
        success_rate = job_data[job_idx,].sum(where=job_data[job_idx,]>0.0) / len(job_row)
        present_rate = 1.0 * len(job_row) / len(revisions)
        print(f"{job_name}: missing {100.0 * (1.0 - present_rate):.2f}% success rate: {100 * success_rate:.2f}%")
    cov_matrix = np.corrcoef(job_data)
    plot_heatmap(cov_matrix, job_names)


def parse_arguments():
    from argparse import ArgumentParser
    parser = ArgumentParser(description="Download and analyze circle logs")
    parser.add_argument('--branch', type=str)
    parser.add_argument('--item_count', type=int, default=100)
    parser.add_argument('--compute_covariance', choices=['cuda_test', 'cuda_build', 'windows_test'])
    return parser.parse_args()

if __name__ == '__main__':
    args = parse_arguments()
    if args.compute_covariance is not None:
        name_filter = {
                'cuda_test': filter_cuda_test,
                'cuda_build': filter_cuda_build,
                'windows_test': filter_windows_test,
                }[args.compute_covariance]
        compute_covariance(branch=args.branch, name_filter=name_filter)
        sys.exit(0)
    fetch_status(branch=args.branch, item_count=args.item_count)
    #plot_graph()
