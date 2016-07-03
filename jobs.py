"""
Usage:
  launch.py
"""

from __future__ import print_function
import sys, os, subprocess
import requests
import json
import argparse
from os import path
from os.path import join
#from docopt import docopt
import yaml

api_url = 'https://api.jarvice.com/jarvice'

#args = docopt(__doc__)

script_dir = path.dirname(path.realpath(__file__))

def get_jobs(config):
  username = config['username']
  apikey = config['apikey']

  res = requests.get('%s/jobs?username=%s&apikey=%s' % (api_url, username, apikey))
  res = json.loads(res.content.decode('utf-8'))
  jobs = []
  for jobnumber, info in res.items():
#    print(json.dumps(info, indent=2))
#    print(jobnumber, info['job_api_submission']['nae']['name'])
    job = {}
    job['number'] = jobnumber
    job['image'] = info['job_api_submission']['nae']['name']
    job['type'] = info['job_api_submission']['machine']['type']
    job['count'] = int(info['job_api_submission']['machine']['nodes'])
    jobs.append(job)
  return jobs

if __name__ == '__main__':
  parser = argparse.ArgumentParser()
  parser.add_argument('--configfile', default=join(script_dir, 'nimbix.yaml'))
  args = parser.parse_args()

  config_path = args.configfile
  if not config_path.startswith('/'):
      config_path = join(script_dir, config_path)

  with open(config_path, 'r') as f:
    config = yaml.load(f)

  for job in get_jobs(config):
    print(job['type'], job['image'], job['count'])
#  print(get_jobs())

