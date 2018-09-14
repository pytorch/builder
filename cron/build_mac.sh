#!/bin/bash

set -ex
echo "build_mac.sh at $(pwd) starting at $(date) on $(uname -a) with pid $$ with pid $$"
SOURCE_DIR=$(cd $(dirname $0) && pwd)
source "${SOURCE_DIR}/nightly_defaults.sh"

# Handles building for mac wheels and mac conda packages and mac libtorch packages.
# Env variables that should be set:
#   PYTORCH_BUILD_VERSION
#     This is the version string, e.g. 0.4.1 , that will be used as the
#     pip/conda version, OR the word 'nightly', which signals all the
#     downstream scripts to use the current date as the version number (plus
#     other changes). This is NOT the conda build string.
#
#   PYTORCH_BUILD_NUMBER
#     This is usually the number 1. If more than one build is uploaded for the
#     same version/date, then this can be incremented to 2,3 etc in which case
#     '.post2' will be appended to the version string of the package. This can
#     be set to '0' only if OVERRIDE_PACKAGE_VERSION is being used to bypass
#     all the version string logic in downstream scripts.
#
#   NIGHTLIES_FOLDER
#     An arbitrary root folder to store all nightlies folders, each of which is
#     a parent level date folder with separate subdirs for logs, wheels, conda
#     packages, etc. This should be kept the same across all scripts called in
#     a cron job, so it only has a default value in the top-most script
#     build_cron.sh to avoid the default values from diverging.
#
#   NIGHTLIES_DATE
#     The date in YYYY_mm_dd format that we are building for. This defaults to
#     the current date. Sometimes cron uses a different time than that returned
#     by `date`, so ideally this is set once by the top-most script
#     build_cron.sh so that all scripts use the same date.

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
  desired_cuda="$3"
fi
if [[ "$package_type" != 'conda' && "$package_type" != 'wheel' && "$package_type" != 'libtorch' ]]; then
    echo "The package type must be 'conda' or 'wheel' or 'libtorch'"
    exit 1
fi

echo "Building a $package_type package for python$desired_python"
echo "Starting to run the build at $(date)"

# Move to today's workspace folder
mkdir -p "$today" || true

# Make the workdir for the mac builds
workdir="${today}/wheel_build_dirs/${package_type}_${desired_python}"
export MAC_PACKAGE_WORK_DIR="$workdir"
rm -rf "$workdir"
mkdir -p "$workdir"

# Copy the pytorch directory into the workdir
cp -R "$NIGHTLIES_PYTORCH_ROOT" "$workdir"

# Build the package
if [[ "$package_type" == 'conda' ]]; then
    # Conda package settings
    export TORCH_PACKAGE_NAME="$(echo $TORCH_PACKAGE_NAME | tr '_' '-')"
    export MAC_PACKAGE_FINAL_FOLDER="$MAC_CONDA_FINAL_FOLDER"
    "${NIGHTLIES_BUILDER_ROOT}/conda/build_pytorch.sh"
    ret="$?"
else
    if [[ "$package_type" == 'libtorch' ]]; then
        export BUILD_PYTHONLESS=1
    fi

    # Wheel settings
    export TORCH_PACKAGE_NAME="$(echo $TORCH_PACKAGE_NAME | tr '-' '_')"
    export MAC_PACKAGE_FINAL_FOLDER="$MAC_WHEEL_FINAL_FOLDER"
    building_wheels=1
    "${NIGHTLIES_BUILDER_ROOT}/wheel/build_wheel.sh"
    ret="$?"
fi

# Mark this build as a success. build_multiple expects this file to be
# written if the build succeeds
 if [[ "$ret" == 0 && -n "$ON_SUCCESS_WRITE_ME" ]]; then
     echo 'SUCCESS' > "$ON_SUCCESS_WRITE_ME"
 fi

 exit "$ret"
