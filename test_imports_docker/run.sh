#!/bin/bash
set -ex

nvidia-docker stop img || true

# If any of these fail, they'll leave behind a running docker container
# named img.
# Remove it with `docker stop img` or attach it and see what's up with
# `docker attach img`. The following is needed to debug inside container:
#     export PATH="/opt/conda/bin:$PATH"

# UNCOMMENT WHAT YOU NEED:

# pytorch installs 
#./test-script.sh nvidia/cuda:9.0-base install-conda-ubuntu.sh install-pytorch-conda.sh import-torch.sh
#./test-script.sh nvidia/cuda:8.0-runtime-ubuntu14.04 install-conda-ubuntu.sh install-pytorch-conda.sh import-torch.sh

# pytorch / tf
#./test-script.sh nvidia/cuda:9.0-base install-conda-ubuntu.sh install-tf-conda.sh install-pytorch-conda.sh import-pytorch-tf.sh

# The following crashes:
# ./test-script.sh nvidia/cuda:9.0-base install-conda-ubuntu.sh install-tf-conda.sh install-pytorch-conda.sh import-tf-pytorch.sh

# This is OK
# ./test-script.sh nvidia/cuda:8.0-runtime-ubuntu14.04 install-conda-ubuntu.sh install-tf-conda.sh install-pytorch-conda.sh import-pytorch-tf.sh

# this also crashes:
# ./test-script.sh nvidia/cuda:8.0-runtime-ubuntu14.04 install-conda-ubuntu.sh install-tf-conda.sh install-pytorch-conda.sh import-tf-pytorch.sh

# pytorch / scipy 
# ./test-script.sh nvidia/cuda:9.0-base install-conda-ubuntu.sh install-scipy-conda.sh install-pytorch-conda.sh import-pytorch-scipy.sh
#./test-script.sh nvidia/cuda:9.0-base install-conda-ubuntu.sh install-scipy-conda.sh install-pytorch-conda.sh import-scipy-pytorch.sh
#./test-script.sh nvidia/cuda:8.0-runtime-ubuntu14.04 install-conda-ubuntu.sh install-scipy-conda.sh install-pytorch-conda.sh import-pytorch-scipy.sh
#./test-script.sh nvidia/cuda:8.0-runtime-ubuntu14.04 install-conda-ubuntu.sh install-scipy-conda.sh install-pytorch-conda.sh import-scipy-pytorch.sh


# pytorch / cv2 
# ./test-script.sh nvidia/cuda:9.0-base install-conda-ubuntu.sh install-cv2-conda.sh install-pytorch-conda.sh import-pytorch-cv2.sh

# The following crashes:
# ./test-script.sh nvidia/cuda:9.0-base install-conda-ubuntu.sh install-cv2-conda.sh install-pytorch-conda.sh import-cv2-pytorch.sh

# This is OK
# ./test-script.sh nvidia/cuda:8.0-runtime-ubuntu14.04 install-conda-ubuntu.sh install-cv2-conda.sh install-pytorch-conda.sh import-pytorch-cv2.sh
# ./test-script.sh nvidia/cuda:8.0-runtime-ubuntu14.04 install-conda-ubuntu.sh install-cv2-conda.sh install-pytorch-conda.sh import-cv2-pytorch.sh

# Older scripts, that were used in 0.4 testing
# ./test-script.sh ubuntu:14.04 install-conda-ubuntu.sh install-pytorch-whl.sh
# ./test-script.sh ubuntu:16.04 install-conda-ubuntu.sh install-pytorch-whl.sh
#./test-script.sh centos:6 install-conda-centos.sh install-pytorch-conda.sh
# ./test-script.sh centos:6 install-conda-centos.sh install-pytorch-whl.sh

# pytorch / tf compatability (cpu-only)
#./test-script.sh ubuntu:16.04 install-conda-ubuntu.sh install-tf-conda.sh install-pytorch-conda.sh import-tf-pytorch.sh import-pytorch-tf.sh
# ./test-script.sh ubuntu:14.04 install-conda-ubuntu.sh install-tf-conda.sh install-pytorch-whl.sh import-tf-pytorch.sh import-pytorch-tf.sh
#./test-script.sh ubuntu:16.04 install-conda-ubuntu.sh install-tf-pip.sh install-pytorch-conda.sh import-tf-pytorch.sh import-pytorch-tf.sh
# ./test-script.sh ubuntu:14.04 install-conda-ubuntu.sh install-tf-pip.sh install-pytorch-whl.sh import-tf-pytorch.sh import-pytorch-tf.sh

# pytorch / cv2 (opencv3) compatibility (cpu-only)
# ./test-script.sh ubuntu:16.04 install-conda-ubuntu.sh install-cv2-conda.sh install-pytorch-whl.sh import-cv2-pytorch.sh import-pytorch-cv2.sh
#./test-script.sh ubuntu:16.04 install-conda-ubuntu.sh install-cv2-conda.sh install-pytorch-conda.sh import-cv2-pytorch.sh import-pytorch-cv2.sh

