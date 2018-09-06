#!/bin/bash

# Script hardcoded to the number of worker machines we have.
# Divides work amongst the workers and runs the jobs in parallel on each worker
#
# Needs NIGHTLIES_FOLDER to point to /scratch/<username>/nightlies
# TODO ^ needs support in all the other scripts too
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

which_worker=$1

if [[ -z "$NIGHTLIES_FOLDER" ]]; then
    NIGHTLIES_FOLDER='/scratch/hellemn/nightlies/'
fi
SOURCE_DIR=$(cd $(dirname $0) && pwd)

# Worker 0
# manywheel py2.7m,py2.7mu,py3.5m all
if [[ "$which_worker" == 0 ]]; then
    log_root="$NIGHTLIES_FOLDER/$(date +%Y_%m_%d)/logs/master/worker_0"
    mkdir -p "$log_root"
    /cron/prep_nightlies.sh > "$log_root/prep_nightlies.log" 2>&1
    "$SOURCE_DIR/build_multiple.sh" manywheel py2.7m,py2.7mu,py3.5 cpu > "$log_root/manywheel_py2.7m_py2.7mu_py3.5_cpu.log" 2>&1 &
    "$SOURCE_DIR/build_multiple.sh" manywheel py2.7m,py2.7mu,py3.5 cu80 > "$log_root/manywheel_py2.7m_py2.7mu_py3.5_cu80.log" 2>&1 &
    "$SOURCE_DIR/build_multiple.sh" manywheel py2.7m,py2.7mu,py3.5 cu90 > "$log_root/manywheel_py2.7m_py2.7mu_py3.5_cu90.log" 2>&1 &
    "$SOURCE_DIR/build_multiple.sh" manywheel py2.7m,py2.7mu,py3.5 cu92 > "$log_root/manywheel_py2.7m_py2.7mu_py3.5_cu92.log" 2>&1 &
fi

# Worker 1
# manywheel py3.6m,py3.7m all
# conda py2.7 all
if [[ "$which_worker" == 1 ]]; then
    log_root="$NIGHTLIES_FOLDER/$(date +%Y_%m_%d)/logs/master/worker_1"
    mkdir -p "$log_root"
    "$SOURCE_DIR/prep_nightlies.sh" > "$log_root/prep_nightlies.log" 2>&1
    "$SOURCE_DIR/build_multiple.sh" manywheel py3.6m cpu,cu80,cu90 > "$log_root/manywheel_py3.6m_cpu_cu80_cu90.log" 2>&1 &
    "$SOURCE_DIR/build_multiple.sh" manywheel py3.7m cpu,cu80,cu90 > "$log_root/manywheel_py3.7m_cpu_cu80_cu90.log" 2>&1 &
    "$SOURCE_DIR/build_multiple.sh" manywheel py3.6m,py3.7m cu92 > "$log_root/manywheel_py3.6m_py3.7m_cu92.log" 2>&1 &
    "$SOURCE_DIR/build_multiple.sh" conda py2.7 all > "$log_root/conda_py2.7_all.log" 2>&1 &
fi

# Worker 2
# conda py3.5,py3.6,py3.6 all
if [[ "$which_worker" == 2 ]]; then
    log_root="$NIGHTLIES_FOLDER/$(date +%Y_%m_%d)/logs/master/worker_2"
    mkdir -p "$log_root"
    "$SOURCE_DIR/prep_nightlies.sh" > "$log_root/prep_nightlies.log" 2>&1
    "$SOURCE_DIR/build_multiple.sh" conda py3.5,py3.6,py3.7 cpu > "$log_root/conda_py3.5_py3.6_py3.7_cpu.log" 2>&1 &
    "$SOURCE_DIR/build_multiple.sh" conda py3.5,py3.6,py3.7 cu80 > "$log_root/conda_py3.5_py3.6_py3.7_cu80.log" 2>&1 &
    "$SOURCE_DIR/build_multiple.sh" conda py3.5,py3.6,py3.7 cu90 > "$log_root/conda_py3.5_py3.6_py3.7_cu90.log" 2>&1 &
    "$SOURCE_DIR/build_multiple.sh" conda py3.5,py3.6,py3.7 cu92 > "$log_root/conda_py3.5_py3.6_py3.7_cu92.log" 2>&1 &
fi
