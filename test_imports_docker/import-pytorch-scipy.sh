#!/bin/bash
set -e

export PATH="/opt/conda/bin:$PATH"
export CMAKE_PREFIX_PATH="/opt/conda"

python -c "import torch; import scipy; print(torch.__version__); print(scipy.__version__)"
