#!/usr/bin/env bash

set -eou pipefail

conda install -yq conda-build conda-verify
(
    set -x
    conda build --output-folder ffmpeg/output "recipe"
)
