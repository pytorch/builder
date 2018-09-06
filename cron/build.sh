#!/bin/bash

# Parameters
##############################################################################

if [ "$#" -ne 3 ]; then
    echo 'Illegal number of parameters'
    echo '     build.sh (conda|manywheel) DESIRED_PYTHON DESIRED_CUDA'
    echo 'e.g. build.sh manywheel 2.7mu cu80'
    echo 'e.g. build.sh conda 2.7 cpu'
    echo ' DESIRED_PYTHON must match:   \d.\d(mu?)?'
    echo ' DESIRED_CUDA must match  :   (cpu|cu\d\d)'
    exit 1
fi
package_type="$1"
desired_python="$2"
desired_cuda="$3"

set -ex

# Validate parameters
if [[ "$package_type" != 'conda' && "$package_type" != 'manywheel' ]]; then
    echo "This script doesn't handle packages of type $package_type"
    exit 1
fi
echo "Building a $package_type package for python$desired_python and $desired_cuda"
echo "Starting a new build at $(date)"

# Move to today's workspace folder
if [[ -z "$NIGHTLIES_FOLDER" ]]; then
    NIGHTLIES_FOLDER='/scratch/hellemn/nightlies/'
fi
today="$NIGHTLIES_FOLDER/$(date +%Y_%m_%d)"
if [[ ! -d "$today" ]]; then
    echo "The prep job for today's nightlies has not been run correctly"
    exit 1
fi
builder_root_dir="${today}/builder"
pytorch_root_dir="${today}/pytorch"
host_package_dir="$today"
docker_package_dir="/host_machine_pkgs"

# Map cuda/python/storage dirs for conda or manywheel
python_nodot="${desired_python:0:1}${desired_python:2:1}"
if [[ "$desired_cuda" == 'cpu' ]]; then
    build_for_cpu=1
else
    cuda_nodot="${desired_cuda:2:2}"
fi
if [[ "$package_type" == 'conda' ]]; then
    desired_python="${desired_python:0:3}"
    if [[ -n "$build_for_cpu" ]]; then
        desired_cuda='cpu'
    else
        desired_cuda="$cuda_nodot"
    fi
    build_script='/remote/conda/build_pytorch.sh'
    docker_image="soumith/conda-cuda"
else
    building_manywheels=1
    if [[ "$desired_python" == '2.7mu' ]]; then
        desired_python='cp27-cp27mu'
    else
        desired_python="cp${python_nodot}-cp${python_nodot}m"
    fi
    # desired_cuda is correct
    if [[ -n "$build_for_cpu" ]]; then
        build_script='/remote/manywheel/build_cpu.sh'
    else
        build_script='/remote/manywheel/build.sh'
    fi
    if [[ -n "$build_for_cpu" ]]; then
        docker_image="soumith/manylinux-cuda80"
    else
        docker_image="soumith/manylinux-cuda$cuda_nodot"
    fi
fi

# Set default parameters
if [[ -z "$TORCH_PACKAGE_NAME" ]]; then
    # TODO handle pips converting - to _
    if [[ -n "$building_manywheels" ]]; then
        TORCH_PACKAGE_NAME='torch_nightly'
    else
        TORCH_PACKAGE_NAME='torch-nightly'
    fi
fi
if [[ -z "$PYTORCH_BUILD_VERSION" ]]; then
    PYTORCH_BUILD_VERSION='nightly'
fi
if [[ -z "$PYTORCH_BUILD_NUMBER" ]]; then
    PYTORCH_BUILD_NUMBER='1'
fi


# Build up Docker Arguments
##############################################################################
docker_args=""

# Needs pseudo-TTY for /bin/cat to hang around
docker_args+="-t"

# Detach so we can use docker exec to run stuff
docker_args+=" -d"

# Increase shared memory size so that we can run bigger models in Docker container
# See: https://github.com/pytorch/pytorch/issues/2244
#docker_args+=" --shm-size 8G"

# Mount pytorch/builder, pytorch/pytorch, and the package storage folder
docker_args+=" -v ${builder_root_dir}:/remote"
docker_args+=" -v ${pytorch_root_dir}:/pytorch"
docker_args+=" -v ${host_package_dir}:${docker_package_dir}"

# Run Docker as the user of this script
# This prevents using the CUDA on the docker images
 #docker_args+=" --user $(id -u):$(id -g)"

# Image
docker_args+=" ${docker_image}"
##############################################################################

# We start a container and detach it such that we can run
# a series of commands without nuking the container
echo "Starting container for image ${docker_image}"
id=$(nvidia-docker run ${docker_args} /bin/cat)

trap "echo 'Stopping container...' &&
docker rm -f $id > /dev/null" EXIT

# I found the only way to make the command below return the proper
# exit code is by splitting run and exec. Executing run directly
# doesn't propagate a non-zero exit code properly.
(
    echo "export DESIRED_PYTHON=${desired_python}"
    echo "export DESIRED_CUDA=${desired_cuda}"
    # the following line is true from the docker's perspective
    echo "export HOST_PACKAGE_DIR=${docker_package_dir}"
    echo "export CMAKE_ARGS=${CMAKE_ARGS[@]}"
    echo "export EXTRA_CAFFE2_CMAKE_FLAGS=${EXTRA_CAFFE2_CMAKE_FLAGS[@]}"
    echo "export RUN_TEST_PARAMS=${RUN_TEST_PARAMS}"
    echo "export TORCH_PACKAGE_NAME=${TORCH_PACKAGE_NAME}"
    echo "export PYTORCH_BUILD_VERSION=${PYTORCH_BUILD_VERSION}"
    echo "export PYTORCH_BUILD_NUMBER=${PYTORCH_BUILD_NUMBER}"
    echo "export OVERRIDE_PACKAGE_VERSION=${OVERRIDE_PACKAGE_VERSION}"
    echo "export FULL_CAFFE2=${FULL_CAFFE2}"
    echo "export DEBUG=${DEBUG}"
    echo "export AWS_ACCESS_KEY_ID="$AWS_ACCESS_KEY_ID"
    echo "export AWS_SECRET_ACCESS_KEY="$AWS_SECRET_ACCESS_KEY"

    echo "cd /"

    # Instal mkldnn
    # TODO this is expensive and should be moved into the Docker images themselves
    # echo '/remote/install_mkldnn.sh'

    # Run the build script
    echo "$build_script"
) | nvidia-docker exec -i "$id" bash

exit 0
