#!/usr/bin/env bash

set -eou pipefail

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

LATEST_COMMIT=$(git rev-parse HEAD)
FOLDER_COMMIT=$(git log -1 --format=format:%H --full-diff $DIR)

if [ $FOLDER_COMMIT = $LATEST_COMMIT ]; then
    echo "FFMpeg has changed"
    ./$DIR/build_ffmpeg.sh

    echo "Uploading FFmpeg to PyTorch Anaconda channel"
    anaconda upload -u pytorch --force $DIR/output/*/ffmpeg*.bz2
else
    echo "No changes in FFmpeg"
    exit 0;
fi
