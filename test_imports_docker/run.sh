#!/bin/bash
set -ex

# If any of these fail, they'll leave behind a running docker container
# named img.
# Remove it with `docker stop img` or attach it and see what's up with
# `docker attach img`. The following is needed to debug inside container:
#     export PATH="/opt/conda/bin:$PATH"

# pytorch installs on cpu-only dockers
./test-script.sh ubuntu:12.04 install-conda-ubuntu.sh install-pytorch-conda.sh
./test-script.sh ubuntu:12.04 install-conda-ubuntu.sh install-pytorch-whl.sh
./test-script.sh ubuntu:14.04 install-conda-ubuntu.sh install-pytorch-conda.sh
./test-script.sh ubuntu:14.04 install-conda-ubuntu.sh install-pytorch-whl.sh
./test-script.sh ubuntu:16.04 install-conda-ubuntu.sh install-pytorch-conda.sh
./test-script.sh ubuntu:16.04 install-conda-ubuntu.sh install-pytorch-whl.sh
./test-script.sh centos:6 install-conda-centos.sh install-pytorch-conda.sh
./test-script.sh centos:6 install-conda-centos.sh install-pytorch-whl.sh

# pytorch / tf compatability (cpu-only)
./test-script.sh ubuntu:14.04 install-conda-ubuntu.sh install-tf-conda.sh install-pytorch-conda.sh import-tf-pytorch.sh import-pytorch-tf.sh
./test-script.sh ubuntu:14.04 install-conda-ubuntu.sh install-tf-conda.sh install-pytorch-whl.sh import-tf-pytorch.sh import-pytorch-tf.sh
./test-script.sh ubuntu:14.04 install-conda-ubuntu.sh install-tf-pip.sh install-pytorch-conda.sh import-tf-pytorch.sh import-pytorch-tf.sh
./test-script.sh ubuntu:14.04 install-conda-ubuntu.sh install-tf-pip.sh install-pytorch-whl.sh import-tf-pytorch.sh import-pytorch-tf.sh

# pytorch / cv2 (opencv3) compatibility (cpu-only)
./test-script.sh ubuntu:14.04 install-conda-ubuntu.sh install-cv2-conda.sh install-pytorch-whl.sh import-cv2-pytorch.sh import-pytorch-cv2.sh
./test-script.sh ubuntu:14.04 install-conda-ubuntu.sh install-cv2-conda.sh install-pytorch-conda.sh import-cv2-pytorch.sh import-pytorch-cv2.sh

