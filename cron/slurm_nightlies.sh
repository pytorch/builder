#!/bin/bash

set -ex

if [[ -z "$SLURM_PROCID" ]]; then
    echo "This script should be run in a slurm environment and needs to know"
    echo "what the SLURM_PROCID is"
    exit 1
fi

# List 'em
all_tasks=(
    'manywheel 2.7m  cpu '
    'manywheel 2.7m  cu80'
    'manywheel 2.7m  cu90'
    'manywheel 2.7m  cu92'

    'manywheel 2.7mu cpu '
    'manywheel 2.7mu cu80'
    'manywheel 2.7mu cu90'
    'manywheel 2.7mu cu92'

    'manywheel 3.5m  cpu '
    'manywheel 3.5m  cu80'
    'manywheel 3.5m  cu90'
    'manywheel 3.5m  cu92'

    'manywheel 3.6m  cpu '
    'manywheel 3.6m  cu80'
    'manywheel 3.6m  cu90'
    'manywheel 3.6m  cu92'

    'manywheel 3.7m  cpu '
    'manywheel 3.7m  cu80'
    'manywheel 3.7m  cu90'
    'manywheel 3.7m  cu92'

    'conda 2.7 cpu '
    'conda 2.7 cu80'
    'conda 2.7 cu90'
    'conda 2.7 cu92'

    'conda 3.5 cpu '
    'conda 3.5 cu80'
    'conda 3.5 cu90'
    'conda 3.5 cu92'

    'conda 3.6 cpu '
    'conda 3.6 cu80'
    'conda 3.6 cu90'
    'conda 3.6 cu92'

    'conda 3.7 cpu '
    'conda 3.7 cu80'
    'conda 3.7 cu90'
    'conda 3.7 cu92'
)

if [[ "${all_tasks[@]}" != 36 ]]; then
    echo 'The number of tasks has drifted. I am no longer sure which
    echo 'configuration to build for'
    exit 1
fi
