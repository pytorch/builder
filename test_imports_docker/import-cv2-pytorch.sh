#!/bin/bash
set -e

export PATH="/opt/conda/bin:$PATH"
export CMAKE_PREFIX_PATH="/opt/conda"

python -c "import cv2; import torch; print(torch.__version__); print(cv2.__version__)"
