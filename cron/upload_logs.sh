#!/bin/bash

set -ex
echo "upload_logs.sh at $(pwd) starting at $(date) on $(uname -a) with pid $$"
SOURCE_DIR=$(cd $(dirname $0) && pwd)
source "${SOURCE_DIR}/nightly_defaults.sh"

# Uploads all of the logs
# N.B. do NOT include the master logs, as there may be secrets in those

pushd "$today/logs"
all_logs=($(find . -name '*.log' -not -path '*master*'))
for log in "${all_logs[@]}"; do
    echo "Copying $log to s3://pytorch/$LOGS_S3_DIR/"
    aws s3 cp "$log" "s3://pytorch/$LOGS_S3_DIR/" --acl public-read
done
popd
