#!/bin/bash

set -ex
SOURCE_DIR=$(cd $(dirname $0) && pwd)

# Parameters
##############################################################################
if [[ "$#" < 1 ]]; then
    echo "Usage: backfill_binary_sizes start_date [end_date=today]"
    echo "Dates in format YYYY_mm_dd"
    exit 1
else
    start_date=$1
    if [[ "$#" < 2 ]]; then
        stop_date="$(date +%Y_%m_%d)"
    else
        stop_date=$2
    fi
fi
start_dash="$(echo $start_date | tr _ -)"


days_passed=0
next_date="$start_date"
loop_limit=100

while [[ "$next_date" != "$stop_date" ]]; do

    # Upload binary sizes!
    "${SOURCE_DIR}/upload_binary_sizes.sh" "$next_date"

    # No infinite loop if dates are badly formatted
    if (( "$days_passed" > "$loop_limit" )); then
        break
    fi

    # Move on to next day, the date arithmetic requires - instead of _
    days_passed=$(($days_passed + 1))
    next_date=$(date +%Y-%m-%d -d "$start_dash + $days_passed day" | tr - _)
done
