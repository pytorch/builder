#!/bin/bash

set -ex
echo "clean.sh at $(pwd) starting at $(date) on $(uname -a) with pid $$"
SOURCE_DIR=$(cd $(dirname $0) && pwd)
source "${SOURCE_DIR}/nightly_defaults.sh"

# Only run the clean on the current day, not on manual re-runs of past days
if [[ "$NIGHTLIES_DATE" != "$(date +%Y_%m_%d)" ]]; then
    echo "Not running clean.sh script"
    exit 0
fi

# Delete everything older than a specified number of days (default is 5)
first_err=0
cutoff_date=$(date --date="$DAYS_TO_KEEP days ago" +%Y_%m_%d)
for build_dir in "$NIGHTLIES_FOLDER"/*; do
    cur_date="$(basename $build_dir)"
    if [[ "$cur_date" < "$cutoff_date" || "$cur_date" == "$cutoff_date" ]]; then
        echo "DELETING BUILD_FOLDER $build_dir !!"
        set +e
        rm -rf "$build_dir"
        ret="$?"
        set -e

        # Store the first error code so that we can alert through email if
        # there was a failure
        if [[ "$first_err" == 0 ]]; then
            first_err="$ret"
        fi
    fi
done

exit "$first_err"
