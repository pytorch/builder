#!/usr/bin/env python

"""
TODO: This was hard to read in pkg_helpers.bash, so I've extracted it
to its own script.  This script is not yet being called by
pkg_helpers.bash yet.
"""


import os
import sys
import json
import re

cuver = os.environ.get('CU_VERSION')
cuver = (cuver[:-1] + '.' + cuver[-1]).replace('cu', 'cuda') if cuver != 'cpu' else cuver

pytorch_entries = json.load(sys.stdin)['pytorch']

filtered_pytorch_entries_plat_cuda = list(filter(
    lambda x: (x['platform'] == 'darwin' or cuver in x['fn']), pytorch_entries
))

filtered_pytorch_entries_py_ver = list(filter(
    lambda x: 'py' + os.environ['PYTHON_VERSION'] in x['fn'], filtered_pytorch_entries_plat_cuda
))

versions = [x['version'] for x in filtered_pytorch_entries_py_ver]

try:
    last_entry = versions[-1]
    print(re.sub(r'\\+.*$', '', last_entry))

except Exception as e:

    all_platforms = set([x['platform'] for x in pytorch_entries])
    all_fns = set([x['fn'] for x in pytorch_entries])

    msg = "\n\t".join([
        "Exception was: " + str(e),
        "Unfiltered entries count: " + str(len(pytorch_entries)),
        "Filtered by platform count: " + str(len(filtered_pytorch_entries_plat_cuda)),
        "all_platforms:\n" + "".join(map(lambda x: "\t\t" + str(x) + "\n", all_platforms)),
        "all_fns:\n" + "".join(map(lambda x: "\t\t" + str(x) + "\n", all_fns)),
    ])

    sys.exit(msg)
