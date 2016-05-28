"""
Usage:
  launch.py [options]

Options:
  --type TYPE    type, eg ng0 for bfboost, or ngd3 for dual Titan X [default: ng0]
  --image IMAGE   image [default: foo]
"""

from __future__ import print_function
import sys
import yaml
import requests
from docopt import docopt

api_url = 'https://api.jarvice.com/jarvice'

args = docopt(__doc__)
instancetype = args['--type']
image = args['--image']

with open('nimbix.yaml', 'r') as f:
  config = yaml.load(f)

print('config', config)
username = config['username']
apikey = config['apikey']

launch_data = {
  "machine": {
    "nodes": "1",
    "type": instancetype
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

