#!/bin/bash
set -e

export PATH="/opt/conda/bin:$PATH"
export CMAKE_PREFIX_PATH="/opt/conda"

apt-get install -y libgtk2.0-0
conda install -y -c menpo opencv3

