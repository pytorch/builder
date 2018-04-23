#!/bin/bash
set -e

export PATH="/opt/conda/bin:$PATH"
export CMAKE_PREFIX_PATH="/opt/conda"

python -c "import torch as th; x = th.autograd.Variable(th.rand(1, 3, 2, 2)); l = th.nn.Upsample(scale_factor=2); print(l(x))"
