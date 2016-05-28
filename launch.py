"""
Usage:
  launch.py
"""

from __future__ import print_function
import sys
import yaml
import requests
from docopt import docopt

api_url = 'https://api.jarvice.com/jarvice'

args = docopt(__doc__)

with open('nimbix.yaml', 'r') as f:
  config = yaml.load(f)

print('config', config)
username = config['username']
apikey = config['apikey']

launch_data = {
  "machine": {
    "nodes": "1",
    "type": "ng0"
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
    "name": "foo",
    "geometry": "1904x881",
    "ephemeral": False,
    "staging": True,
    "interactive": True
  }
}

res = requests.post('%s/submit' % api_url, json=launch_data)
print(res.status_code)
print(res.content)
print(res.status_code)

