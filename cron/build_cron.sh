#!/bin/bash

set -ex
echo "build_cron.sh at $(pwd) starting at $(date) on $(uname -a)"
SOURCE_DIR=$(cd $(dirname $0) && pwd)
source "${SOURCE_DIR}/nightly_defaults.sh"

# Script hardcoded to the number of worker machines we have.
# Divides work amongst the workers and runs the jobs in parallel on each worker
#
# Command line arguments
#   DESIRED_PYTHONS
#     All Python versions to build for, separated by commas, in format '2.7mu'
#     for manywheels or in format '2.7' for conda/mac-wheels e.g.
#     '2.7m,2.7mu,3.5m,3.6m' or '2.7,3.7' . This can also just be the word
#     'all', which will expand to all supported python versions.
#
#   DESIRED_CUDAS
#     All CUDA versions to build for including 'cpu', separated by commas, in
#     format 'cpu' or 'cu80' or 'cu92' etc. e.g. 'cpu,cu80,cu90' or 'cu90,cu92'
#     . This can also just be the word 'all', which will expand to all
#     supported cpu/CUDA versions.

# On mac there is only one machine, so not specifying which machine is fine
if [[ "$(uname)" == 'Darwin' ]]; then
    which_worker='mac'
else
    if [ "$#" -ne 1 ]; then
        echo "Illegal number of parameters. Require which worker I am [0-2] or 'mac'"
        echo "e.g. ./build_cron.sh 0"
        exit 1
    fi
    
    which_worker=$1
    
    # This file is hardcoded to exactly 3 linux workers and 1 mac worker
    if [[ "$which_worker" != 0 && "$which_worker" != 1 && "$which_worker" != 2 ]]; then
        echo "Illegal parameter. This script is made for exactly 3 workers."
        echo "You must give me a worker number out of [0, 1, 2] or 'mac'"
        exit 1
    fi
fi

mkdir -p "${today}/logs/failed" || true
mkdir -p "${today}/logs/succeeded" || true

# Divy up the tasks
#
# There are currently 36 jobs and 3 machines
# Each machine should run its 12 jobs in 4 parallel batches, about
# conda jobs and gpu jobs take longer
#
# The jobs is the combination of all:
# manywheel X [2.7m 2.7mu 3.5m 3.6m 3.7m] X [cpu cu80 cu90 cu92]
# conda     X [2.7        3.5  3.6  3.7 ] X [cpu cu80 cu90 cu92]
# wheel     X [2.7        3.5  3.6  3.7 ] X [cpu               ]
#
# cpu builds ~ 15 minutes. gpu builds > 1 hr
# Try to divide the cpu jobs evenly among the  tasks
if [[ "$which_worker" == 0 ]]; then
    # manywheel 2.7m,2.7mu,3.5m all
    tasks=(
        'manywheel 2.7m cpu,cu80,cu90'
        'manywheel 2.7mu cpu,cu80,cu90'
        'manywheel 3.5m cpu,cu80,cu90'
        'manywheel 2.7m,2.7mu,3.5m cu92'
    )
elif [[ "$which_worker" == 1 ]]; then
    # manywheel 3.6m,3.7, all
    # conda 2.7 all
    tasks=(
        'manywheel 3.6m cpu,cu80,cu90'
        'manywheel 3.7m cpu,cu80,cu90'
        'conda 2.7 cpu,cu80,cu90'
        'manywheel 3.6m,3.7m cu92  -- conda 2.7 cu92'
    )
elif [[ "$which_worker" == 2 ]]; then
    # conda 3.5,3.6,3.7 all
    tasks=(
        'conda 3.5 cpu,cu80,cu90'
        'conda 3.6 cpu,cu80,cu90'
        'conda 3.7 cpu,cu80,cu90'
        'conda 3.5,3.6,3.7 cu92'
    )
elif [[ "$which_worker" == 'mac' ]]; then
    # wheel all
    # conda all cpu
    # 'conda 3.5,3.6,3.7 cpu'
    # 'wheel 3.7 cpu -- conda 2.7 cpu'
    tasks=(
        'wheel 2.7,3.5 cpu'
        'wheel 3.6,3.7 cpu'
    )
fi

# Run the tasks
log_root="$today/logs/master/worker_$which_worker"
mkdir -p "$log_root"
for task in "${tasks[@]}"; do
    log_file="$log_root/$(echo $task | tr ' ' '_' | tr -d ',-').log"
    "${NIGHTLIES_BUILDER_ROOT}/cron/build_multiple.sh" $task > "$log_file" 2>&1 &
done

# TODO capture PIDs of processes and wait for them to call upload.sh
