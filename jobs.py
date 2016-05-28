"""
Usage:
  launch.py
"""

from __future__ import print_function
import sys, os, subprocess
import requests
import json
from docopt import docopt
import yaml

api_url = 'https://api.jarvice.com/jarvice'

args = docopt(__doc__)

with open('nimbix.yaml', 'r') as f:
  config = yaml.load(f)

username = config['username']
apikey = config['apikey']

res = requests.get('%s/jobs?username=%s&apikey=%s' % (api_url, username, apikey))
res = json.loads(res.content.decode('utf-8'))

for jobnumber, info in res.items():
  print(jobnumber, info['job_api_submission']['nae']['name'])
#  print('jobnumber', jobnumber)
#  if info['job_api_submission']['nae']['name'] == image:
#    target_jobnumber = jobnumber
#    break

