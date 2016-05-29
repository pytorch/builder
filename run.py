"""
Spin up an instance, run a single command, spin it down :-)

Usage:
  run.py [options] -- <COMMAND> ...
  run.py [options] <COMMAND> ...

Options:
  --type TYPE    type, eg ng0 for bfboost, or ngd3 for dual Titan X [default: ng0]
  --image IMAGE   image [default: s1]
"""

from __future__ import print_function
import sys
import yaml
import json
import requests
import time
from docopt import docopt
from util.logtailer import LogTailer

api_url = 'https://api.jarvice.com/jarvice'

args = docopt(__doc__)
instancetype = args['--type']
image = args['--image']
command = args['<COMMAND>']
print('command', command)

with open('nimbix.yaml', 'r') as f:
  config = yaml.load(f)

username = config['username']
apikey = config['apikey']

launch_data = {
  "machine": {
    "nodes": "1",
    "type": instancetype
  },
  "variables": {
    "FOO": "BAR"
  },
  "vault": {
    "readonly": False,
    "force": False,
    "name": "drop.jarvice.com"
  },
  "user": {
    "username": username,
    "apikey": apikey
  },
  "nae": {
    "force": False,
    "name": image,
#    "geometry": "1904x881",
    "command": " ".join(command),
    "ephemeral": False,
    "staging": True,
    "interactive": False
  }
}

res = requests.post('%s/submit' % api_url, json=launch_data)
assert res.status_code == 200
res = json.loads(res.content.decode('utf-8'))

jobnumber = res['number']
print('jobnumber %s' % jobnumber)

logtailer = LogTailer(username=username, apikey=apikey, jobnumber=jobnumber)
while True:
  res = requests.get('%s/status?username=%s&apikey=%s&number=%s' % (api_url, username, apikey, jobnumber))
  assert res.status_code == 200
  res = json.loads(res.content.decode('utf-8'))
  status = res[str(jobnumber)]['job_status']
  logtailer.updateFromTail()
  if 'COMPLETED' in status:
    break
  time.sleep(1)

logtailer.updateFromOutput()

res = requests.get('%s/status?username=%s&apikey=%s&number=%s' % (api_url, username, apikey, jobnumber))
assert res.status_code == 200
res = json.loads(res.content.decode('utf-8'))
print('wall time %s' % res[str(jobnumber)]['job_walltime'])

