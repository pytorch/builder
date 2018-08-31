#!/bin/bash

set -x

if [ "$#" -ne 3 ]; then
    echo 'Illegal number of parameters'
    echo '     build_multiple.sh (conda|manywheel) DESIRED_PYTHON,s DESIRED_CUDA,s'
    echo 'e.g. build.sh manywheel 2.7mu,3.5,3.6 cpu,cu80'
    echo 'e.g. build.sh conda 2.7 all'
    echo ' DESIRED_PYTHONs must match:   \d.\d(mu?)?'
    echo ' DESIRED_CUDAs must match  :   (cpu|cu\d\d)'
    exit 1
fi

today="/scratch/nightlies/$(date +%Y_%m_%d)"
SOURCE_DIR=$(cd $(dirname $0) && pwd)

package_type=$1
IFS=, all_pythons=($2)
IFS=, all_cuda=($3)

# Allow 'all' to translate to all python/cuda versions
if [[ "${all_pythons[0]}" == 'all' ]]; then
    if [[ "$package_type" == 'conda' ]]; then
        all_pythons=('2.7' '3.5' '3.6' '3.7')
    else
        all_pythons=('2.7m' '2.7mu' '3.5m' '3.6m' '3.7m')
    fi
fi
if [[ "${all_cuda[0]}" == 'all' ]]; then
    all_cuda=('cpu' 'cu80' 'cu90' 'cu92')
fi

# Build over all combinations
for py_ver in "${all_pythons[@]}"; do
    for cuda_ver in "${all_cuda[@]}"; do
        echo "Building for $package_type for py$py_ver and $cuda_ver"
        "$SOURCE_DIR/build_and_log.sh" "$package_type" "$py_ver" "$cuda_ver"
    done
done
