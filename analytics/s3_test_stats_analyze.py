import argparse
import boto3
import bz2
import json
import os
import re
import requests

import pandas as pd

from datetime import datetime, timedelta
from tqdm import tqdm
from typing import Any, Dict, Optional, List

S3 = boto3.resource('s3')
CLIENT = boto3.client('s3')
BUCKET = S3.Bucket('ossci-metrics')

GITHUB_API_BASE = "https://api.github.com/"
GITHUB_COMMITS_API = "repos/pytorch/pytorch/commits"
STRF_FORMAT = "%Y-%m-%dT%H:%M:%SZ"

CACHE_PICKLE = "cache/test_time/dataframe.pickle"

def _get_latests_git_commit_sha_list(lookback: int):
    sha_since = (datetime.utcnow() - timedelta(hours = lookback)).strftime(STRF_FORMAT)
    resp = requests.get(GITHUB_API_BASE + GITHUB_COMMITS_API + f"?since={sha_since}")
    if resp.status_code == 200:
        return [e.get('sha') for e in resp.json()]
    else:
        return []

def _json_to_df(data: Dict[str, Any], granularity: str) -> pd.DataFrame:
    reformed_data = list()
    for fname, fdata in data['files'].items():
        if granularity == 'file': 
            reformed_data.append({
                "job": data['job'],
                "sha": data['sha'],
                'file': fname,
                'file_total_sec': fdata['total_seconds'],
            })
        else:
            for sname, sdata in fdata['suites'].items():
                if granularity == 'suite': 
                    reformed_data.append({
                        "job": data['job'],
                        "sha": data['sha'],
                        'suite': sname,
                        'suite_total_sec': sdata['total_seconds'],
                    })
                else:
                    for cname, cdata in sdata['cases'].items():
                        reformed_data.append({
                            "job": data['job'],
                            "sha": data['sha'],
                            'case': cname,
                            'case_status': cdata['status'],
                            'case_sec': cdata['seconds'],
                            })
    df = pd.json_normalize(reformed_data)
    return df


def download_stats(folder: str, lookback: int):
    commit_sha_list = _get_latests_git_commit_sha_list(lookback)
    for commit_sha in commit_sha_list:
        for key in tqdm(BUCKET.objects.filter(Prefix=f'test_time/{commit_sha}')):
            remote_fname = key.key
            local_fname = os.path.join(folder, remote_fname)
            # TODO: Do this in parallel
            if not os.path.exists(local_fname):
                dirname = os.path.dirname(local_fname)
                if not os.path.exists(dirname):
                    os.makedirs(dirname)
                # only download when there's a cache miss
                if not os.path.exists(local_fname) or not os.path.isfile(local_fname):
                    print(f"\nDownloading {remote_fname}...")
                    CLIENT.download_file("ossci-metrics", remote_fname, local_fname)


def parse_and_export_stats(folder: str, granularity: str, commit_sha_lists: Optional[List[str]] = None):
    dataframe = None
    for (dirpath, _, filenames) in os.walk(folder):
        for filename in tqdm(filenames):
            splits = dirpath.split("/")
            job_name = splits[-1]
            sha = splits[-2]
            if not commit_sha_lists or sha in commit_sha_lists:
                with bz2.open(os.path.join(dirpath, filename), 'r') as zf:
                    string = zf.read().decode("utf-8")
                    data = json.loads(string)
                    # create a deep json with sha and job info
                    data['sha'] = sha
                    data['job'] = job_name
                    df = _json_to_df(data, granularity)
                    dataframe = df if dataframe is None else dataframe.append(df)
    return dataframe


def main():
    parser = argparse.ArgumentParser(
        __file__,
        description="download and cache test stats locally, both raw and pandas format",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    parser.add_argument(
        '--lookback',
        type=int,
        help='lookback in # of hours',
        default=24,
    )
    parser.add_argument(
        '--output',
        help='output filename',
        default='cache/df.pickle',
    )
    parser.add_argument(
        '--cache_folder',
        help='cache folder',
        default='cache',
    )
    parser.add_argument(
        '--granularity',
        choices=['file', 'suite', 'case'],
        help='granularity of stats summary',
        default='file',
    )
    args = parser.parse_args()

    lookback = args.lookback
    cache_folder = args.cache_folder
    output = args.output
    granularity = args.granularity

    print("Downloading test stats")
    download_stats(cache_folder, lookback)
    print("Parsing test stats and write to pd dataframe")
    if not os.path.exists(output):
        dataframe = parse_and_export_stats(f'{cache_folder}/test_time/', granularity)
        dataframe.to_pickle(output)

                

if __name__ == "__main__":
    main()
    
