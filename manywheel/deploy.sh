set -e
nvidia-docker build -t soumith/manylinux-cuda80 -f Dockerfile .
nvidia-docker build -t soumith/manylinux-cuda75 -f Dockerfile_75 .
nvidia-docker build -t soumith/manylinux-cuda90 -f Dockerfile_90 .
#docker push soumith/manylinux-cuda
