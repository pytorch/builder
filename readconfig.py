# reads the config.yaml file, and prints values for use in a bash eval $() scenario, like:
# eval $(python readconfig.py)
# echo jenkinspassword

from __future__ import print_function
import yaml
from os import path
from os.path import join

script_dir = path.dirname(path.realpath(__file__))

with open(join(script_dir, 'config.yaml'), 'r') as f:
  config = yaml.load(f)
#print('config', config)

for k, v in config.items():
  print('%s=%s' % (k,v))

