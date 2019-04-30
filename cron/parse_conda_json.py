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
    print('parse_conda_json.py:: Parsing package {}'.format(pkg_name))

    # Loop through versions found, keeping only 'build', and size
    # size is in bytes
    for result in rawdata[pkg_name]:
        size = result['size']
        # 'build' is of the form 'py2.7_cuda8.0.61_cudnn7.1.2_0' for cuda builds
        # or 'py2.7_cpu_0' for cpu builds
        build = result['build'].split('_')
        assert len(build) == 3 or len(build) == 4, "Unexpected build string {}".format(build)

        print('parse_conda_json.py:: Size of {} is {}'.format(build, size))

        # Python versions are of form 'py#.#' , we discard the 'py'
        py_ver = build[0][2:]

        # CUDA versions are of the form 'cuda10.0.61', we replace 'cuda' with
        # 'cu' and keep only the major and minor values
        if build[1] == 'cpu':
            cu_ver = 'cpu'
        else:
            cu_ver = build[1][4:].split('.')
            assert len(cu_ver) == 3, "Unexpected cuda format {}".format(cu_ver)
            cu_ver = 'cu' + ''.join((cu_ver[0], cu_ver[1]))

        # N.B. platform is queried as 'linux-64' but is stores as linux, and as
        # 'osx-64' but stored as 'darwin'
        plat = 'linux' if 'linux' in result['platform'] else 'macos'

        data.append((plat, py_ver, cu_ver, size))

# Write the sizes out in log_name format of conda_2.7_cu80
print("parse_conda_json.py:: Writing log_name format to {}".format(outputfile))
with open(outputfile, 'a') as outfile:
    for plat, py_ver, cu_ver, size in data:
        outfile.write("{} conda {} {} {}\n".format(plat, py_ver, cu_ver, size))
