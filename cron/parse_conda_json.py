import json
import sys

# Usage:
#   parse_conda_json.py input_file output_file
# Reads the result of a `conda search --json` into lines of '<platform>
# <log_name> <size>'

inputfile = sys.argv[1]
outputfile = sys.argv[2]

data = []

with open(inputfile, 'rb') as jsonfile:
    rawdata = json.load(jsonfile)

    # conda search returns format {'pytorch-nightly': [{key:val}...]}
    pkg_name = list(rawdata.keys())[0]

    # Loop through versions found, keeping only 'build', and size
    # size is in bytes
    for result in rawdata[pkg_name]:
        size = result['size']

        # 'build' is of the form 'py2.7_cuda8.0.61_cudnn7.1.2_0'
        # Since all Python versions are always 3 digits, it is safe to extract
        # the CUDA version based on index alone.
        build = result['build']
        py_ver = build[2:5]
        cu_ver = ('cu' + build[10] + build[12]) if 'cuda' in build else 'cpu'

        # N.B. platform is queried as 'linux-64' but is stores as linux, and as
        # 'osx-64' but stored as 'darwin'
        plat = 'linux' if 'linux' in result['platform'] else 'macos'

        data.append((plat, py_ver, cu_ver, size))

# Write the sizes out in log_name format of conda_2.7_cu80
with open(outputfile, 'a') as outfile:
    for plat, py_ver, cu_ver, size in data:
        outfile.write("{} conda {} {} {}\n".format(plat, py_ver, cu_ver, size))
