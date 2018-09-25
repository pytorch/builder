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
any_removal_failed=0
cutoff_date=$(date --date="$DAYS_TO_KEEP days ago" +%Y_%m_%d)
for build_dir in "$NIGHTLIES_FOLDER"/*; do
    cur_date="$(basename $build_dir)"
    if [[ "$cur_date" < "$cutoff_date" || "$cur_date" == "$cutoff_date" ]]; then
        echo "DELETING BUILD_FOLDER $build_dir !!"

        # Remove the folder
        # Technically, this should condition on whether a mac or docker
        # produces the packages, but the linux jobs only run on linux machines
        # so this is fine.
        if [[ "$(uname)" == 'Darwin' ]]; then
            rm -rf "$build_dir"
        else
            # So, the dockers don't have a proper user setup, so they all run as
            # root. When they write their finished packages to the host system,
            # they can't be deleted without sudo access. Actually fixing the
            # permissions in the docker involves both setting up a correct user and
            # adding sudo in the right places to yum, pip, conda, and CUDA
            # functionality. Instead of all that, we run the rm command in a
            # different docker image, since the dockers all run as root.
            docker run -v "${NIGHTLIES_FOLDER}":/remote soumith/conda-cuda rm -rf "/remote/$cur_date"
        fi

        # Make sure the rm worked, in this case we want this next command to
        # fail
        set +e
        ls "$build_dir" >/dev/null 2>&1
        ret="$?"
        set -e
        if [[ "$ret" == 0 ]]; then
            any_removal_failed=1
            echo "ERROR | "
            echo "ERROR | Could not remove $build_dir"
            echo "ERROR | Please try to delete $build_dir manually"
            echo "ERROR | Then fix builder/cron/clean.sh"
        fi
    fi
done

exit "$any_removal_failed"
