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

set -ex

if [ "$#" -ne 1 ]; then
    echo "Illegal number of parameters. Require which worker I am [0-2]"
    echo "e.g. ./build_cron.sh 0"
    exit 1
fi

which_worker=$1

if [[ -z "$NIGHTLIES_FOLDER" ]]; then
    NIGHTLIES_FOLDER='/scratch/hellemn/nightlies/'
fi
today="$NIGHTLIES_FOLDER/$(date +%Y_%m_%d)"
SOURCE_DIR=$(cd $(dirname $0) && pwd)

# Worker 0
# manywheel 2.7m,2.7mu,3.5m all
if [[ "$which_worker" == 0 ]]; then
    log_root="$today/logs/master/worker_0"
    mkdir -p "$log_root"
    "$SOURCE_DIR/prep_nightlies.sh" > "$log_root/prep_nightlies.log" 2>&1
    "$SOURCE_DIR/build_multiple.sh" manywheel 2.7m,2.7mu,3.5 cpu > "$log_root/manywheel_2.7m_2.7mu_3.5_cpu.log" 2>&1 &
    "$SOURCE_DIR/build_multiple.sh" manywheel 2.7m,2.7mu,3.5 cu80 > "$log_root/manywheel_2.7m_2.7mu_3.5_cu80.log" 2>&1 &
    "$SOURCE_DIR/build_multiple.sh" manywheel 2.7m,2.7mu,3.5 cu90 > "$log_root/manywheel_2.7m_2.7mu_3.5_cu90.log" 2>&1 &
    "$SOURCE_DIR/build_multiple.sh" manywheel 2.7m,2.7mu,3.5 cu92 > "$log_root/manywheel_2.7m_2.7mu_3.5_cu92.log" 2>&1 &
fi

# Worker 1
# manywheel 3.6m,3.7m all
# conda 2.7 all
if [[ "$which_worker" == 1 ]]; then
    log_root="$today/logs/master/worker_1"
    mkdir -p "$log_root"
    "$SOURCE_DIR/prep_nightlies.sh" > "$log_root/prep_nightlies.log" 2>&1
    "$SOURCE_DIR/build_multiple.sh" manywheel 3.6m cpu,cu80,cu90 > "$log_root/manywheel_3.6m_cpu_cu80_cu90.log" 2>&1 &
    "$SOURCE_DIR/build_multiple.sh" manywheel 3.7m cpu,cu80,cu90 > "$log_root/manywheel_3.7m_cpu_cu80_cu90.log" 2>&1 &
    "$SOURCE_DIR/build_multiple.sh" manywheel 3.6m,3.7m cu92 > "$log_root/manywheel_3.6m_3.7m_cu92.log" 2>&1 &
    "$SOURCE_DIR/build_multiple.sh" conda 2.7 all > "$log_root/conda_2.7_all.log" 2>&1 &
fi

# Worker 2
# conda 3.5,3.6,3.6 all
if [[ "$which_worker" == 2 ]]; then
    log_root="$today/logs/master/worker_2"
    mkdir -p "$log_root"
    "$SOURCE_DIR/prep_nightlies.sh" > "$log_root/prep_nightlies.log" 2>&1
    "$SOURCE_DIR/build_multiple.sh" conda 3.5,3.6,3.7 cpu > "$log_root/conda_3.5_3.6_3.7_cpu.log" 2>&1 &
    "$SOURCE_DIR/build_multiple.sh" conda 3.5,3.6,3.7 cu80 > "$log_root/conda_3.5_3.6_3.7_cu80.log" 2>&1 &
    "$SOURCE_DIR/build_multiple.sh" conda 3.5,3.6,3.7 cu90 > "$log_root/conda_3.5_3.6_3.7_cu90.log" 2>&1 &
    "$SOURCE_DIR/build_multiple.sh" conda 3.5,3.6,3.7 cu92 > "$log_root/conda_3.5_3.6_3.7_cu92.log" 2>&1 &
fi
