from __future__ import print_function
import sys
import yaml
import argparse
import requests

api_url = 'https://api.jarvice.com/jarvice'

parser = argparse.ArgumentParser()
parser.add_argument('--type', help='type, eg ng0 for bfboost, or ngd3 for dual Titan X')
parser.add_argument('--image', default='ng0', help='image name (basically, container name, more or less)')
args = parser.parse_args()

with open('nimbix.yaml', 'r') as f:
  config = yaml.load(f)

instancetype = args.type
image = args.image
if instancetype is None:
    instancetype = config['type_by_instance'].get(image, image)
print('instancetype: %s' % instancetype)

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

