#!/bin/bash

# Script hardcoded to the number of worker machines we have.
# Divides work amongst the workers and runs the jobs in parallel on each worker
#
# Needs NIGHTLIES_FOLDER to point to /scratch/<username>/nightlies
#
# There are currently 36 jobs and 3 machines
# Each machine should run its 12 jobs in 4 parallel batches, about
# conda jobs and gpu jobs take longer
#
# The list of jobs is
#all_tasks=(
#    'manywheel 2.7m  cpu '
#    'manywheel 2.7m  cu80'
#    'manywheel 2.7m  cu90'
#    'manywheel 2.7m  cu92'
#
#    'manywheel 2.7mu cpu '
#    'manywheel 2.7mu cu80'
#    'manywheel 2.7mu cu90'
#    'manywheel 2.7mu cu92'
#
#    'manywheel 3.5m  cpu '
#    'manywheel 3.5m  cu80'
#    'manywheel 3.5m  cu90'
#    'manywheel 3.5m  cu92'
#
#    'manywheel 3.6m  cpu '
#    'manywheel 3.6m  cu80'
#    'manywheel 3.6m  cu90'
#    'manywheel 3.6m  cu92'
#
#    'manywheel 3.7m  cpu '
#    'manywheel 3.7m  cu80'
#    'manywheel 3.7m  cu90'
#    'manywheel 3.7m  cu92'
#
#    'conda 2.7 cpu '
#    'conda 2.7 cu80'
#    'conda 2.7 cu90'
#    'conda 2.7 cu92'
#
#    'conda 3.5 cpu '
#    'conda 3.5 cu80'
#    'conda 3.5 cu90'
#    'conda 3.5 cu92'
#
#    'conda 3.6 cpu '
#    'conda 3.6 cu80'
#    'conda 3.6 cu90'
#    'conda 3.6 cu92'
#
#    'conda 3.7 cpu '
#    'conda 3.7 cu80'
#    'conda 3.7 cu90'
#    'conda 3.7 cu92'
#)
#
# cpu builds ~ 15 minutes. gpu builds > 1 hr
# Try to divide the cpu jobs evenly among the  tasks

set -ex

if [ "$#" -ne 1 ]; then
    echo "Illegal number of parameters. Require which worker I am [0-2]"
    echo "e.g. ./build_cron.sh 0"
    exit 1
fi

which_worker=$1

# This file is hardcoded to exactly 3 workers
if [[ "$which_worker" != 0 && "$which_worker" != 1 && "$which_worker" != 2 ]]; then
    echo "Illegal parameter. This script is made for exactly 3 workers."
    echo "You must give me a worker number out of [0, 1, 2]"
    exit 1
fi

if [[ -z "$NIGHTLIES_FOLDER" ]]; then
    if [[ "$(uname)" == 'Darwin' ]]; then
        export NIGHTLIES_FOLDER='/Users/administrator/nightlies/'
    else
        export NIGHTLIES_FOLDER='/scratch/hellemn/nightlies'
    fi
fi
if [[ -z "$NIGHTLIES_DATE" ]]; then
    # cron can use a different time than is returned by `date`, so we save
    # the date that we're starting with so all builds use the same date
    export NIGHTLIES_DATE="$(date +%Y_%m_%d)"
fi
today="$NIGHTLIES_FOLDER/$NIGHTLIES_DATE"
SOURCE_DIR=$(cd $(dirname $0) && pwd)

# Divy up the tasks
if [[ "$which_worker" == 0 ]]; then
    tasks=(
        'manywheel 2.7m cpu,cu80,cu90'
        'manywheel 2.7mu cpu,cu80,cu90'
        'manywheel 3.5m cpu,cu80,cu90'
        'manywheel 2.7m,2.7mu,3.5m cu92'
    )
elif [[ "$which_worker" == 1 ]]; then
    tasks=(
        'manywheel 3.6m cpu,cu80,cu90'
        'manywheel 3.7m cpu,cu80,cu90'
        'conda 2.7 cpu,cu80,cu90'
        'manywheel 3.6m,3.7m cu92  -- conda 2.7 cu92'
    )
elif [[ "$which_worker" == 2 ]]; then
    tasks=(
        'conda 3.5 cpu,cu80,cu90'
        'conda 3.6 cpu,cu80,cu90'
        'conda 3.7 cpu,cu80,cu90'
        'conda 3.5,3.6,3.7 cu92'
    )
fi

# Run the tasks
log_root="$today/logs/master/worker_$which_worker"
mkdir -p "$log_root"
"$SOURCE_DIR/prep_nightlies.sh" 2>&1 | tee "$log_root/prep_nightlies.log"
for task in "${tasks[@]}"; do
    log_file="$log_root/$(echo $task | tr ' ' '_' | tr -d ',-').log"
    "$SOURCE_DIR/build_multiple.sh" $task > "$log_file" 2>&1 &
done
