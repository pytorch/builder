#!/bin/bash

set -ex

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

echo
echo 'Starting PyTorch binary build.'
echo "$(date) :: Starting PyTorch binaries build"
echo "Building $package_type for [${all_cuda[@]}] x [${all_pythons[@]}]"

# Build over all combinations
for py_ver in "${all_pythons[@]}"; do
    for cuda_ver in "${all_cuda[@]}"; do
        log_name="${today}/logs/$1_$2_$3"
        echo
        echo "$(date) :: Starting $package_type for py$py_ver and $cuda_ver"
        echo "Placing the log in $log_name"

        set +e
        "$SOURCE_DIR/build.sh" "$package_type" "$py_ver" "$cuda_ver" 2>&1 | tee "$log_name"
        ret="$?"
        set -e

        # Keep track of the failed builds
        if [[ "$ret" != 0 ]]; then
            echo "$(date) :: Build status of $package_type for py$py_ver and $cuda_ver :: FAILURE!"
            echo "$1_$2_$3" >> "${today}/logs/failed"
        else
            echo "$(date) :: Build status of $package_type for py$py_ver and $cuda_ver :: SUCCESS!"
        fi
    done
done
