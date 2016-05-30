"""
Usage:
  launch.py
"""

from __future__ import print_function
import sys, os, subprocess
import requests
import json
from os import path
from os.path import join
from docopt import docopt
import yaml

api_url = 'https://api.jarvice.com/jarvice'

args = docopt(__doc__)

script_dir = path.dirname(path.realpath(__file__))

with open(join(script_dir, 'nimbix.yaml'), 'r') as f:
  config = yaml.load(f)

username = config['username']
apikey = config['apikey']

def get_jobs():
  res = requests.get('%s/jobs?username=%s&apikey=%s' % (api_url, username, apikey))
  res = json.loads(res.content.decode('utf-8'))
  jobs = []
  for jobnumber, info in res.items():
#    print(json.dumps(info, indent=2))
#    print(jobnumber, info['job_api_submission']['nae']['name'])
    job = {}
#    job['number'] = jobnumber
    job['image'] = info['job_api_submission']['nae']['name']
    job['type'] = info['job_api_submission']['machine']['type']
    job['count'] = int(info['job_api_submission']['machine']['nodes'])
    jobs.append(job)
  return jobs

if __name__ == '__main__':
  for job in get_jobs():
    print(job['type'], job['image'], job['count'])
#  print(get_jobs())

