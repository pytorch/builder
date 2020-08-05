#!/usr/bin/env bash

set -eou pipefail

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

BASE_COMMIT=$(git merge-base --fork-point origin/master)
FOLDER_COMMIT=$(git log -1 --format=format:%H --full-diff $DIR)

git merge-base --is-ancestor FOLDER_COMMIT BASE_COMMIT

if [ $? -eq 0 ]; then
    echo "FFMpeg has changed"
    ./$DIR/build_ffmpeg.sh
else
    echo "No changes in FFmpeg"
    exit 0;
fi
