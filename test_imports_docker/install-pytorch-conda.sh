#!/bin/bash
set -e

export PATH="/opt/conda/bin:$PATH"
export CMAKE_PREFIX_PATH="/opt/conda"

conda install -y pytorch-nightly -c pytorch
python -c "import torch; print(torch.__version__)"
