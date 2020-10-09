#!/usr/bin/env bash

set -eou pipefail

if [[ "$OSTYPE" == "msys" ]]; then
    FFMPEG_TARBALL=$(find tmp -type f -name *.tar.gz)
    echo $FFMPEG_TARBALL
fi

conda install -yq conda-build conda-verify
(
    set -x
    conda build --output-folder ffmpeg/output "ffmpeg/recipe"
)
