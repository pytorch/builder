from __future__ import print_function, unicode_literals

import sys
import os
from os import path
from os.path import join
import os.path
import yaml

#script_dir = path.dirname(path.realpath(__file__))

def checkChanges(filepath, data):
  newString = yaml.safe_dump(data, default_flow_style = False )

  oldString = ''
  if os.path.isfile(filepath):
    f = open(filepath,'r')
    oldString = f.read()
    f.close()

  changesString = ''
  if(newString != oldString):
    changesString += 'changed:\n'
    changesString += 'old:\n'
    changesString += oldString + '\n'
    changesString += 'new:\n'
    changesString += newString + '\n'
    with open('%s~' % filepath, 'w') as f:
      f.write( newString )
    os.rename('%s~' % filepath, filepath)
  return changesString

