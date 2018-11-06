#!/bin/bash

# Uploads all logs to s3, takes no arguments.
# The log location is configured in cron/nightly_defaults.sh
#
# This is called by upload.sh, since upload.sh contains all the logic to set up
# conda and pip with credentials. This exists as a separate file so that you
# can manually just update the logs if you wish by just calling this file.
#
# If you call this yourself then you are responsible for your own credentials.
# N.B. PLEASE BE CAREFUL. In the past, it seems like manually logging in to
# anaconda has caused problems to cron's ability to login to Anaconda and
# prevented uploading.

set -ex
echo "upload_logs.sh at $(pwd) starting at $(date) on $(uname -a) with pid $$"
SOURCE_DIR=$(cd $(dirname $0) && pwd)
source "${SOURCE_DIR}/nightly_defaults.sh"

# Uploads all of the logs
# N.B. do NOT include the master logs, as there are secrets in those

pushd "$today/logs"
all_logs=($(find . -name '*.log' -not -path '*master*'))
for log in "${all_logs[@]}"; do
    echo "Copying $log to s3://pytorch/$LOGS_S3_DIR/"
    aws s3 cp "$log" "s3://pytorch/$LOGS_S3_DIR/" --acl public-read
done
popd
