#!/usr/bin/env bash

set -eou pipefail

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

docker run --rm -i \
    -v $(git rev-parse --show-toplevel):/builder \
    -w /builder \
    "pytorch/conda-cuda:latest" \
    ffmpeg/build_ffmpeg.sh
