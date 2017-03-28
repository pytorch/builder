set -e
nvidia-docker build -t soumith/manylinux-cuda .
docker push soumith/manylinux-cuda
