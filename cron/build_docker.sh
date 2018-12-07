#!/bin/bash

set -ex

echo "build_docker.sh at $(pwd) starting at $(date) on $(uname -a) with pid $$"
SOURCE_DIR=$(cd $(dirname $0) && pwd)
source "${SOURCE_DIR}/nightly_defaults.sh"

# Handles building for manywheels and linux conda packages.

# Parameters
##############################################################################
if [[ "$#" != 3 ]]; then
  if [[ -z "$DESIRED_PYTHON" || -z "$DESIRED_CUDA" || -z "$PACKAGE_TYPE" ]]; then
      echo "The env variabled PACKAGE_TYPE must be set to 'conda' or 'manywheel' or 'libtorch'"
      echo "The env variabled DESIRED_PYTHON must be set like '2.7mu' or '3.6m' etc"
      echo "The env variabled DESIRED_CUDA must be set like 'cpu' or 'cu80' etc"
      exit 1
  fi
  package_type="$PACKAGE_TYPE"
  desired_python="$DESIRED_PYTHON"
  desired_cuda="$DESIRED_CUDA"
else
  package_type="$1"
  desired_python="$2"
  desired_cuda="$3"
fi
if [[ "$package_type" != 'conda' && "$package_type" != 'manywheel' && "$package_type" != 'libtorch' ]]; then
    echo "The package type must be 'conda' or 'manywheel' or 'libtorch'"
    exit 1
fi

echo "Building a $package_type package for python$desired_python and $desired_cuda"
echo "Starting to run the build at $(date)"

# Organize folders by os, package_type, and cuda version
host_package_dir="$(nightlies_package_folder $package_type $desired_cuda)"
mkdir -p "$host_package_dir" || true

# This is the name of the package dir dockerside
docker_package_dir="/host_machine_pkgs"

# Map cuda/python/storage dirs for conda or manywheel
python_nodot="${desired_python:0:1}${desired_python:2:1}"
if [[ "$desired_cuda" == 'cpu' ]]; then
    build_for_cpu=1
else
    cuda_nodot="${desired_cuda:2}"
fi
if [[ "$package_type" == 'conda' ]]; then
    export TORCH_PACKAGE_NAME="$(echo $TORCH_PACKAGE_NAME | tr '_' '-')"
    desired_python="${desired_python:0:3}"
    if [[ -n "$build_for_cpu" ]]; then
        desired_cuda='cpu'
    else
        desired_cuda="$cuda_nodot"
    fi
    build_script='/remote/conda/build_pytorch.sh'
    docker_image="soumith/conda-cuda"
else
    export TORCH_PACKAGE_NAME="$(echo $TORCH_PACKAGE_NAME | tr '-' '_')"
    if [[ "$package_type" == 'libtorch' ]]; then
        building_pythonless=1
    fi

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
if [[ -n "$ON_SUCCESS_WRITE_ME" ]]; then
    success_folder="$(dirname $ON_SUCCESS_WRITE_ME)"
    success_basename="$(basename $ON_SUCCESS_WRITE_ME)"
fi

# Pull a fresh copy of the docker image
docker pull "$docker_image"

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

# Mount the folder that will collect the finished packages
docker_args+=" -v ${host_package_dir}:${docker_package_dir}"

# Mount the folder that stores the file in which to write SUCCESS at the end
if [[ -n "$success_folder" ]]; then
    docker_args+=" -v $success_folder:/statuses"
fi

# Run Docker as the user of this script
# Without this line, all writes to the host filesystem (all folders in -v
# flags) will be as root, and won't actually be deletable on the host machine
# after the docker exits. But with this flag, yum and other CUDA functionality
# have troubles accessing files they need. So instead of using this line we
# just start up another docker to delete this files at the end
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

# Copy pytorch/builder and pytorch/pytorch into the container
nvidia-docker cp "$NIGHTLIES_BUILDER_ROOT" "$id:/remote"
nvidia-docker cp "$NIGHTLIES_PYTORCH_ROOT" "$id:/pytorch"

# I found the only way to make the command below return the proper
# exit code is by splitting run and exec. Executing run directly
# doesn't propagate a non-zero exit code properly.
(
    echo "export DESIRED_PYTHON=${desired_python}"
    echo "export DESIRED_CUDA=${desired_cuda}"
    # the following line is true from the docker's perspective
    echo "export PYTORCH_FINAL_PACKAGE_DIR=${docker_package_dir}"
    echo "export CMAKE_ARGS=${CMAKE_ARGS[@]}"
    echo "export EXTRA_CAFFE2_CMAKE_FLAGS=${EXTRA_CAFFE2_CMAKE_FLAGS[@]}"
    echo "export RUN_TEST_PARAMS=${RUN_TEST_PARAMS}"
    echo "export TORCH_PACKAGE_NAME=${TORCH_PACKAGE_NAME}"
    echo "export PYTORCH_BUILD_VERSION=${PYTORCH_BUILD_VERSION}"
    echo "export PYTORCH_BUILD_NUMBER=${PYTORCH_BUILD_NUMBER}"
    echo "export OVERRIDE_PACKAGE_VERSION=${OVERRIDE_PACKAGE_VERSION}"
    echo "export TORCH_CONDA_BUILD_FOLDER=${TORCH_CONDA_BUILD_FOLDER}"
    echo "export DEBUG=${DEBUG}"
    echo "export ON_SUCCESS_WRITE_ME=/statuses/$success_basename"

    echo "export BUILD_PYTHONLESS=${building_pythonless}"

    # TODO improve avx512 detection instead of disabling all of fbgemm
    echo "export NO_FBGEMM=1"

    echo "cd /"

    # Run the build script
    echo "$build_script"

    # Mark this build as a success. build_multiple expects this file to be
    # written if the build succeeds
    # Note the ' instead of " so the variables are all evaluated within the
    # docker
    echo 'ret=$?'
    echo 'if [[ $ret == 0 && -n $ON_SUCCESS_WRITE_ME ]]; then'
    echo '    echo 'SUCCESS' > $ON_SUCCESS_WRITE_ME'
    echo 'fi'

    echo 'exit $ret'
) | nvidia-docker exec -i "$id" bash
echo "docker run exited with $?"

exit 0
