set -e
docker build -t pytorch/manylinux-cuda100 -f manywheel/Dockerfile_100 .
docker push pytorch/manylinux-cuda100

docker build -t pytorch/manylinux-cuda92 -f manywheel/Dockerfile_92 .
docker push pytorch/manylinux-cuda92

docker build -t pytorch/manylinux-cuda101 -f manywheel/Dockerfile_101 .
docker push pytorch/manylinux-cuda101
