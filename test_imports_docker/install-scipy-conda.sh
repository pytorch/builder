#!/bin/bash
set -e

export PATH="/opt/conda/bin:$PATH"
export CMAKE_PREFIX_PATH="/opt/conda"

conda install -y scipy
python -c "import scipy; print(scipy.__version__)"
