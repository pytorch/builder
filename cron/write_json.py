import json
import sys

# Usage:
#   write_json.py input_file output_file
# Reads a file of '<platform> <log_name> <size>' into a json file

inputfile = sys.argv[1]
outputfile = sys.argv[2]

data = []

with open(inputfile, 'r') as infile:
    for line in infile:
        platform, pkg_type, py_ver, cu_ver, size = line.split()
        data.append({
            'os': platform,
            'pkgType': pkg_type,
            'pyVer': py_ver,
            'cuVer': cu_ver,
            'size': size,
        })

with open(outputfile, 'w') as outfile:
    json.dump(data, outfile)
