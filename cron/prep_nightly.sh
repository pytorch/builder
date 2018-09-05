#!/bin/bash

# Script prep nightly manywheel and conda jobs by cloning the needed builder
# and pytorch repos

set -ex

# Default parameters
##############################################################################
if [[ -z "$BUILDER_REPO" ]]; then
    BUILDER_REPO='pjh5'
fi
if [[ -z "$BUILDER_BRANCH" ]]; then
    BUILDER_BRANCH='cron'
fi
if [[ -z "$PYTORCH_REPO" ]]; then
    PYTORCH_REPO='pjh5'
fi
if [[ -z "$PYTORCH_BRANCH" ]]; then
    PYTORCH_BRANCH='curand_fix'
fi

# Make the folders needed for today's builds
today="/scratch/hellemn/nightlies/$(date +%Y_%m_%d)"
mkdir -p "${today}/wheelhousecpu"
mkdir -p "${today}/wheelhouse80"
mkdir -p "${today}/wheelhouse90"
mkdir -p "${today}/wheelhouse92"
mkdir -p "${today}/conda"
mkdir -p "${today}/logs"
touch "${today}/logs/failed"
pushd "$today"

# Clone the requested builder checkout
rm -rf builder
git clone "https://github.com/${BUILDER_REPO}/builder.git"
pushd builder
git checkout "$BUILDER_BRANCH"
popd
chmod -w builder

# Clone the requested pytorch checkout
rm -rf pytorch
git clone --recursive "https://github.com/${PYTORCH_REPO}/pytorch.git"
pushd pytorch
git checkout "$PYTORCH_BRANCH"
popd
chmod -w pytorch
