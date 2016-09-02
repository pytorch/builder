"""
Spin up an instance, run a single script, spin it down :-)

Usage:
  run.py [options] <SCRIPTPATH>

Options:
  --type TYPE    type, eg ng0 for bfboost, or ngd3 for dual Titan X [default: ng0]
  --image IMAGE   image [default: s1]
"""

from __future__ import print_function
import sys
import yaml
import json
import requests
import pysftp
import time
from docopt import docopt
from util.logtailer import LogTailer

api_url = 'https://api.jarvice.com/jarvice'
drop_host = 'drop.jarvice.com'

args = docopt(__doc__)
instancetype = args['--type']
image = args['--image']
scriptPath = args['<SCRIPTPATH>']
print('scriptPath', scriptPath)
#command = args['<COMMAND>']
#print('command', command)

with open('nimbix.yaml', 'r') as f:
  config = yaml.load(f)

username = config['username']
apikey = config['apikey']

scriptName = scriptPath.split('/')[-1]
print('scriptName', scriptName)

# need to sftp it up to data first...
with pysftp.Connection(drop_host, username=username, password=apikey) as sftp:
  try:
    sftp.mkdir('temp')
  except:
    pass
#  sftp.cd('temp'):
  sftp.put(scriptPath, "temp/%s" % scriptName)

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
    "command": "bash /data/temp/%s" % scriptName,
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

def get_last_nonblank_index(target):
  index = len(target) - 1
  while index > 0 and target[index] == '':
    index -= 1
  return index

logtailer = LogTailer(username=username, apikey=apikey, jobnumber=jobnumber)
while True:
  res = requests.get('%s/status?username=%s&apikey=%s&number=%s' % (api_url, username, apikey, jobnumber))
  assert res.status_code == 200
  res = json.loads(res.content.decode('utf-8'))
  status = res[str(jobnumber)]['job_status']
  if str(status) == str('SUBMITTED'):
    time.sleep(1)
    continue
  logtailer.updateFromTail()
  if 'COMPLETED' in status:
    break
  time.sleep(1)

logtailer.updateFromOutput()

res = requests.get('%s/status?username=%s&apikey=%s&number=%s' % (api_url, username, apikey, jobnumber))
assert res.status_code == 200
res = json.loads(res.content.decode('utf-8'))
print('wall time %s' % res[str(jobnumber)]['job_walltime'])

