"""
Usage:
  launch.py [options]

Options:
  --image IMAGE      image
"""

from __future__ import print_function
import sys, os, subprocess
import requests
import json
from docopt import docopt
import yaml

api_url = 'https://api.jarvice.com/jarvice'
# ssh_path = '/usr/bin/ssh'

args = docopt(__doc__)
image = args['--image']

with open('nimbix.yaml', 'r') as f:
  config = yaml.load(f)

username = config['username']
apikey = config['apikey']

if image == '' or image is None:
  print('please provide image name')
  sys.exit(1)

res = requests.get('%s/jobs?username=%s&apikey=%s' % (api_url, username, apikey))
#print(res.status_code)

res = json.loads(res.content.decode('utf-8'))
#print('res', res)
#print(res.content.decode('utf-8'))

target_jobnumber = None
for jobnumber, info in res.items():
#  print('jobnumber', jobnumber)
  if info['job_api_submission']['nae']['name'] == image:
    target_jobnumber = jobnumber
    break

assert target_jobnumber is not None
#  print('image', image)
#  if imag

res = requests.get('%s/connect?username=%s&apikey=%s&number=%s' % (api_url, username, apikey, target_jobnumber))
#print(res.status_code)
#print(res.content)
res = json.loads(res.content.decode('utf-8'))
ip_address = res['address']
#print('ip_address', ip_address)
print(ip_address)

