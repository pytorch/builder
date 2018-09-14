#!/bin/bash

set -ex

# Default parameters for nightly builds to be sourced both by build_cron.sh and
# by the build_docker.sh and wheel/build_wheel.sh scripts.

echo "nightly_defaults.sh at $(pwd) starting at $(date) on $(uname -a) with pid $$"

# List of people to email when things go wrong
NIGHTLIES_EMAIL_LIST=('hellemn@fb.com')

# NIGHTLIES_FOLDER
# N.B. this is also defined in cron_start.sh
#   An arbitrary root folder to store all nightlies folders, each of which is a
#   parent level date folder with separate subdirs for logs, wheels, conda
#   packages, etc. This should be kept the same across all scripts called in a
#   cron job, so it only has a default value in the top-most script
#   build_cron.sh to avoid the default values from diverging.
if [[ -z "$NIGHTLIES_FOLDER" ]]; then
    if [[ "$(uname)" == 'Darwin' ]]; then
        export NIGHTLIES_FOLDER='/Users/administrator/nightlies/'
    else
        export NIGHTLIES_FOLDER='/scratch/hellemn/nightlies'
    fi
fi

# NIGHTLIES_DATE
# N.B. this is also defined in cron_start.sh
#   The date in YYYY_mm_dd format that we are building for. This defaults to
#   the current date. Sometimes cron uses a different time than that returned
#   by `date`, so ideally this is set once by the top-most script
#   build_cron.sh so that all scripts use the same date.
if [[ -z "$NIGHTLIES_DATE" ]]; then
    export NIGHTLIES_DATE="$(date +%Y_%m_%d)"
fi

# Used in lots of places as the root dir to store all conda/wheel/manywheel
# packages as well as logs for the day
export today="$NIGHTLIES_FOLDER/$NIGHTLIES_DATE"

# N.B. BUILDER_REPO and BUILDER_BRANCH are both set in cron_start.sh, as that
# is the script that actually clones the builder repo that /this/ script is
# running from.
export NIGHTLIES_BUILDER_ROOT="$(cd $(dirname $0)/.. && pwd)"

# The shared pytorch repo to be used by all builds
export NIGHTLIES_PYTORCH_ROOT="${today}/pytorch"

# PYTORCH_REPO
#   The Github org/user whose fork of Pytorch to check out (git clone
#   https://github.com/<THIS_PART>/pytorch.git). This will always be cloned
#   fresh to build with. Default is 'pytorch'
if [[ -z "$PYTORCH_REPO" ]]; then
    export PYTORCH_REPO='pytorch'
fi

# PYTORCH_BRANCH
#   The branch of Pytorch to checkout for building (git checkout <THIS_PART>).
#   This can either be the name of the branch (e.g. git checkout
#   my_branch_name) or can be a git commit (git checkout 4b2674n...). Default
#   is 'master'
if [[ -z "$PYTORCH_BRANCH" ]]; then
    export PYTORCH_BRANCH='master'
fi

# Clone the requested pytorch checkout
if [[ ! -d "$NIGHTLIES_PYTORCH_ROOT" ]]; then
    git clone --recursive "https://github.com/${PYTORCH_REPO}/pytorch.git" "$NIGHTLIES_PYTORCH_ROOT"
    pushd "$NIGHTLIES_PYTORCH_ROOT"
    git checkout "$PYTORCH_BRANCH"
    popd
fi

# PYTORCH_BUILD_VERSION
#   This is the version string, e.g. 0.4.1 , that will be used as the
#   pip/conda version, OR the word 'nightly', which signals all the
#   downstream scripts to use the current date as the version number (plus
#   other changes). This is NOT the conda build string.
if [[ -z "$PYTORCH_BUILD_VERSION" ]]; then
    export PYTORCH_BUILD_VERSION="1.0.0.dev$(date +%Y%m%d)"
fi

# PYTORCH_BUILD_NUMBER
#   This is usually the number 1. If more than one build is uploaded for the
#   same version/date, then this can be incremented to 2,3 etc in which case
#   '.post2' will be appended to the version string of the package. This can
#   be set to '0' only if OVERRIDE_PACKAGE_VERSION is being used to bypass
#   all the version string logic in downstream scripts. Since we use the
#   override below, exporting this shouldn't actually matter.
if [[ -z "$PYTORCH_BUILD_NUMBER" ]]; then
    export PYTORCH_BUILD_NUMBER='1'
fi
if [[ "$PYTORCH_BUILD_NUMBER" -gt 1 ]]; then
    export PYTORCH_BUILD_VERSION="${PYTORCH_BUILD_VERSION}${PYTORCH_BUILD_NUMBER}"
fi

# The nightly builds use their own versioning logic, so we override whatever
# logic is in setup.py or other scripts
export OVERRIDE_PACKAGE_VERSION="$PYTORCH_BUILD_VERSION"

# Build folder for conda builds to use
if [[ -z "$TORCH_CONDA_BUILD_FOLDER" ]]; then
    export TORCH_CONDA_BUILD_FOLDER='pytorch-nightly'
fi

# TORCH_PACKAGE_NAME
#   The name of the package to upload. This should probably be pytorch or
#   pytorch-nightly. N.B. that pip will change all '-' to '_' but conda will
#   not. This is dealt with in downstream scripts.
if [[ -z "$TORCH_PACKAGE_NAME" ]]; then
    export TORCH_PACKAGE_NAME='torch-nightly'
fi

# PIP_UPLOAD_FOLDER should end in a slash. This is to handle it being empty
# (when uploading to e.g. whl/cpu/) and also to handle nightlies (when
# uploading to e.g. /whl/nightly/cpu)
if [[ -z "$PIP_UPLOAD_FOLDER" ]]; then
    export PIP_UPLOAD_FOLDER='nightly/'
fi

# MAC_(CONDA|WHEEL|LIBTORCH)_FINAL_FOLDER
#   Absolute path to the folders where final conda/wheel packages should be
#   stored
export MAC_CONDA_FINAL_FOLDER="${today}/mac_conda_pkgs"
export MAC_WHEEL_FINAL_FOLDER="${today}/mac_wheels"
export MAC_LIBTORCH_FINAL_FOLDER="${today}/mac_libtorch_packages"

# (FAILED|SUCCEEDED)_LOG_DIR
#   Absolute path to folders that store final logs. Initially these folders
#   should be empty. When a build fails, it's log should be moved to
#   FAILED_LOG_DIR, thus tracking failures/succeeded builds and also keeping
#   logs in a convenient place.
export FAILED_LOG_DIR="${today}/logs/failed"
export SUCCEEDED_LOG_DIR="${today}/logs/succeeded"
