#!/bin/bash

set -ex

if [ "$#" -ne 3 ]; then
    echo 'Illegal number of parameters'
    echo '     build.sh (conda|manywheel) DESIRED_PYTHON DESIRED_CUDA'
    echo 'e.g. build.sh manywheel 2.7mu cu80'
    echo 'e.g. build.sh conda 2.7 cpu'
    echo ' DESIRED_PYTHON must match:   \d.\d(mu?)?'
    echo ' DESIRED_CUDA must match  :   (cpu|cu\d\d)'
    exit 1
fi

today="/scratch/nightlies/$(date +%Y_%m_%d)"
SOURCE_DIR=$(cd $(dirname $0) && pwd)

# Build and save the output
set +e
"$SOURCE_DIR/build.sh" "$@" > "${today}/logs/$1_$2_$3" 2>&1
ret="$?"
set -e

# Just keep track of failed builds for now.
if [[ "$ret" != 0 ]]; then
    echo "$1_$2_$3" >> "${today}/logs/failed"
fi
