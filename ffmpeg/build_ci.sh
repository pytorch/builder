#!/usr/bin/env bash

set -xou pipefail

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

git remote -v
git branch
git fetch origin

FOLDER_COMMIT=$(git log -1 --format=format:%H --full-diff $DIR)
BASE_COMMIT=$(git merge-base --fork-point master)

git merge-base --is-ancestor $FOLDER_COMMIT $BASE_COMMIT
COMMIT_SAME=$?

set -exou pipefail

if [ $COMMIT_SAME -eq 1 ]; then
    echo "FFMpeg has changed"
    $DIR/build_ffmpeg.sh
else
    echo "No changes in FFmpeg"
    exit 0;
fi
