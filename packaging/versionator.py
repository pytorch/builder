#!/usr/bin/env python

"""
TODO: This was hard to read in pkg_helpers.bash, so I've extracted it
to its own script.  This script is not yet being called by
pkg_helpers.bash yet.
"""


import os, sys, json, re
cuver = os.environ.get('CU_VERSION')
cuver = (cuver[:-1] + '.' + cuver[-1]).replace('cu', 'cuda') if cuver != 'cpu' else cuver

versions = [x['version'] for x in json.load(sys.stdin)['pytorch']
                                  if (x['platform'] == 'darwin' or cuver in x['fn'])
                                    and 'py' + os.environ['PYTHON_VERSION'] in x['fn']]
last_entry = versions[-1]

print(re.sub(r'\\+.*$', '', last_entry))

