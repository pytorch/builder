#!/bin/bash
set -e

export PATH="/opt/conda/bin:$PATH"
export CMAKE_PREFIX_PATH="/opt/conda"

apt-get install -qq -y libgtk2.0-0 2>&1 >/dev/null
conda install -y -c menpo opencv3

