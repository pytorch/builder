set -e
nvidia-docker build -t soumith/manylinux-cuda80 -f Dockerfile_80 .
nvidia-docker build -t soumith/manylinux-cuda90 -f Dockerfile_90 .
nvidia-docker build -t soumith/manylinux-cuda91 -f Dockerfile_91 .
#docker push soumith/manylinux-cuda
