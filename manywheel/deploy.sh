set -e
nvidia-docker build -t soumith/manylinux-cuda80 -f Dockerfile_80 .
nvidia-docker build -t soumith/manylinux-cuda90 -f Dockerfile_90 .
nvidia-docker build -t soumith/manylinux-cuda92 -f Dockerfile_92 .
nvidia-docker push soumith/manylinux-cuda80
nvidia-docker push soumith/manylinux-cuda90
nvidia-docker push soumith/manylinux-cuda92
