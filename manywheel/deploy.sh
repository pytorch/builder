set -e
nvidia-docker build -t soumith/manylinux-cuda100 -f manywheel/Dockerfile_100 .
nvidia-docker push soumith/manylinux-cuda100

nvidia-docker build -t soumith/manylinux-cuda92 -f manywheel/Dockerfile_92 .
nvidia-docker push soumith/manylinux-cuda92

nvidia-docker build -t soumith/manylinux-cuda101 -f manywheel/Dockerfile_101 .
nvidia-docker push soumith/manylinux-cuda101
