from __future__ import print_function
import sys
import yaml
from os.path import join
from os import path
import argparse
import requests
import argparse


api_url = 'https://api.jarvice.com/jarvice'
script_dir = path.dirname(path.realpath(__file__))


def launch(config, image, instancetype):
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
    return res.status_code, res.content

if __name__ == '__main__':
    instancetype = None
    config_path = 'nimbix.yaml'
    if len(sys.argv) > 2 or (len(sys.argv) == 2 and sys.argv[1] in ['--help']):
        parser = argparse.ArgumentParser()
        parser.add_argument('--type', help='type, eg ng0 for bfboost, or ngd3 for dual Titan X')
        parser.add_argument('--image', default='ng0', help='image name (basically, container name, more or less)')
        parser.add_argument('--configfile', default=join(script_dir, 'nimbix.yaml'))
        args = parser.parse_args()
        instancetype = args.type
        image = args.image
        config_path = args.configfile
    else:
        image = sys.argv[1]

    if not config_path.startswith('/'):
        config_path = join(script_dir, config_path)

    with open(config_path, 'r') as f:
      config = yaml.load(f)

    if instancetype is None:
        instancetype = config['type_by_instance'].get(image, image)
    print('instancetype: %s' % instancetype)

    status_code, content = launch(config, image, instancetype)
    print(status_code)
    print(content)
    print(status_code)

