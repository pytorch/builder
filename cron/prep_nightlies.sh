#!/bin/bash

# Script prep nightly manywheel and conda jobs by cloning the needed builder
# and pytorch repos

set -ex

# Default parameters
##############################################################################
if [[ -z "$BUILDER_REPO" ]]; then
    BUILDER_REPO='pytorch'
fi
if [[ -z "$BUILDER_BRANCH" ]]; then
    BUILDER_BRANCH='master'
fi
if [[ -z "$PYTORCH_REPO" ]]; then
    PYTORCH_REPO='pytorch'
fi
if [[ -z "$PYTORCH_BRANCH" ]]; then
    PYTORCH_BRANCH='master'
fi
if [[ -z "$NIGHTLIES_FOLDER" ]]; then
    echo "Env variable NIGHTLIES_FOLDER must be set"
    exit 1
fi
if [[ -z "$NIGHTLIES_DATE" ]]; then
    export NIGHTLIES_DATE="$(date +%Y_%m_%d)"
fi
today="$NIGHTLIES_FOLDER/$NIGHTLIES_DATE"

# Make the folders needed for today's builds
mkdir -p "${today}/wheelhousecpu"
mkdir -p "${today}/wheelhouse80"
mkdir -p "${today}/wheelhouse90"
mkdir -p "${today}/wheelhouse92"
mkdir -p "${today}/conda"
mkdir -p "${today}/logs" || true
touch "${today}/logs/failed"
pushd "$today"

# N.B. All the build-jobs on this machine will be accessing these same repos,
# so we set them to read-only so that they do not interfere with each other.

# Clone the requested builder checkout
rm -rf builder
git clone "https://github.com/${BUILDER_REPO}/builder.git"
pushd builder
git checkout "$BUILDER_BRANCH"
popd
chmod -R 555 builder

# Clone the requested pytorch checkout
rm -rf pytorch
git clone --recursive "https://github.com/${PYTORCH_REPO}/pytorch.git"
pushd pytorch
git checkout "$PYTORCH_BRANCH"
popd
chmod -R 555 pytorch
