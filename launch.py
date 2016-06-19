from __future__ import print_function
import sys
import yaml
import argparse
import requests

api_url = 'https://api.jarvice.com/jarvice'

with open('nimbix.yaml', 'r') as f:
  config = yaml.load(f)

username = config['username']
apikey = config['apikey']

def launch(image, instancetype):
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
    return res.status_code, res.content

if __name__ == '__main__':
    instancetype = None
    if len(sys.argv) > 2:
        parser = argparse.ArgumentParser()
        parser.add_argument('--type', help='type, eg ng0 for bfboost, or ngd3 for dual Titan X')
        parser.add_argument('--image', default='ng0', help='image name (basically, container name, more or less)')
        args = parser.parse_args()
        instancetype = args.type
        image = args.image
    else:
        image = sys.argv[1]

    if instancetype is None:
        instancetype = config['type_by_instance'].get(image, image)
    print('instancetype: %s' % instancetype)

    status_code, content = launch(image, instancetype)
    print(status_code)
    print(content)
    print(status_code)

