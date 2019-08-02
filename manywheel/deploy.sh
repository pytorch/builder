set -e
nvidia-docker build -t soumith/manylinux-cuda92 -f Dockerfile_92 .
nvidia-docker build -t soumith/manylinux-cuda100 -f Dockerfile_100 .
nvidia-docker build -t soumith/manylinux-cuda101 -f Dockerfile_101 .
nvidia-docker push soumith/manylinux-cuda92
nvidia-docker push soumith/manylinux-cuda100
nvidia-docker push soumith/manylinux-cuda101
