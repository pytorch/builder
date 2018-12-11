#!/bin/bash

set -ex
echo "build_mac.sh at $(pwd) starting at $(date) on $(uname -a) with pid $$ with pid $$"
SOURCE_DIR=$(cd $(dirname $0) && pwd)
source "${SOURCE_DIR}/nightly_defaults.sh"

# Handles building for mac wheels and mac conda packages and mac libtorch packages.
# Env variables that should be set:

# Parameters
##############################################################################
if [[ "$#" != 2 ]]; then
  if [[ -z "$DESIRED_PYTHON" || -z "$PACKAGE_TYPE" ]]; then
      echo "The env variabled PACKAGE_TYPE must be set to 'conda' or 'manywheel' or 'libtorch'"
      echo "The env variabled DESIRED_PYTHON must be set like '2.7mu' or '3.6m' etc"
      exit 1
  fi
  package_type="$PACKAGE_TYPE"
  desired_python="$DESIRED_PYTHON"
else
  package_type="$1"
  desired_python="$2"
fi
if [[ "$package_type" != 'conda' && "$package_type" != 'wheel' && "$package_type" != 'libtorch' ]]; then
    echo "The package type must be 'conda' or 'wheel' or 'libtorch'"
    exit 1
fi
echo "$(date) Building a $package_type MacOS package for python$desired_python"
export PYTORCH_FINAL_PACKAGE_DIR="$(nightlies_package_folder $package_type cpu)"
mkdir -p "$PYTORCH_FINAL_PACKAGE_DIR"

# Setup a workdir
##############################################################################
workdir="${NIGHTLIES_FOLDER}/wheel_build_dirs/${package_type}_${desired_python}"
export MAC_PACKAGE_WORK_DIR="$workdir"
rm -rf "$workdir"
mkdir -p "$workdir"

# Copy the pytorch directory into the workdir
cp -R "$NIGHTLIES_PYTORCH_ROOT" "$workdir"

# Copy the builder directory into the workdir
# This is needed b/c the conda scripts can alter the meta.yaml
cp -R "$NIGHTLIES_BUILDER_ROOT" "$workdir"

# Build the package
##############################################################################
if [[ "$package_type" == 'conda' ]]; then
    export TORCH_PACKAGE_NAME="$(echo $TORCH_PACKAGE_NAME | tr '_' '-')"
    "${workdir}/builder/conda/build_pytorch.sh" cpu "$PYTORCH_BUILD_VERSION" "$PYTORCH_BUILD_NUMBER"
    ret="$?"
else
    if [[ "$package_type" == 'libtorch' ]]; then
        export BUILD_PYTHONLESS=1
    fi
    export TORCH_PACKAGE_NAME="$(echo $TORCH_PACKAGE_NAME | tr '-' '_')"
    "${workdir}/builder/wheel/build_wheel.sh" "$desired_python" "$PYTORCH_BUILD_VERSION" "$PYTORCH_BUILD_NUMBER"
    ret="$?"
fi

# Mark this build as a success. build_multiple expects this file to be
# written if the build succeeds
 if [[ "$ret" == 0 && -n "$ON_SUCCESS_WRITE_ME" ]]; then
     echo 'SUCCESS' > "$ON_SUCCESS_WRITE_ME"
 fi

 exit "$ret"
