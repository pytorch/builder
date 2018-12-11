#!/bin/bash

set -ex

# Minimal bootstrap to clone the latest pytorch/builder repo and then call
# /that/ repo's build_cron.sh

echo "cron_start.sh at $(pwd) starting at $(date) on $(uname -a)"

# BUILDER_REPO
#   The Github org/user whose fork of builder to check out (git clone
#   https://github.com/<THIS_PART>/builder.git). This will always be cloned
#   fresh to build with. Default is 'pytorch'
if [[ -z "$BUILDER_REPO" ]]; then
    export BUILDER_REPO='pytorch'
fi

# BUILD_BRANCH
#   The branch of builder to checkout for building (git checkout <THIS_PART>).
#   This can either be the name of the branch (e.g. git checkout
#   my_branch_name) or can be a git commit (git checkout 4b2674n...). Default
#   is 'master'
if [[ -z "$BUILDER_BRANCH" ]]; then
    export BUILDER_BRANCH='master'
fi

# N.B. NIGHTLIES_ROOT_FOLDER and NIGHTLIES_DATE are also set in nightly_defaults.sh
# and should be kept the same in both places
if [[ -z "$NIGHTLIES_ROOT_FOLDER" ]]; then
    if [[ "$(uname)" == 'Darwin' ]]; then
        export NIGHTLIES_ROOT_FOLDER='/Users/administrator/nightlies'
    else
        export NIGHTLIES_ROOT_FOLDER='/scratch/hellemn/nightlies'
    fi
fi
if [[ -z "$NIGHTLIES_DATE" ]]; then
    export NIGHTLIES_DATE="$(date +%Y_%m_%d)"
fi
if [[ -z "$NIGHTLIES_FOLDER" ]]; then
    export NIGHTLIES_FOLDER="$NIGHTLIES_ROOT_FOLDER/$NIGHTLIES_DATE"
fi
mkdir -p "$NIGHTLIES_FOLDER" || true


# Clone the requested builder checkout
# This script already exists in a builder repo somewhere, but we don't want to
# manually update the Github repos on every worker machine every time a change
# is made to the builder repo, so we re-clone the latest builder repo, and then
# call /that/ repo's build_cron.sh. We keep this script instead of cloning this
# in the crontab itself for ease of debugging.
if [[ ! -d "$NIGHTLIES_FOLDER/builder" ]]; then
    pushd "$NIGHTLIES_FOLDER"
    rm -rf builder
    git clone "https://github.com/${BUILDER_REPO}/builder.git"
    pushd builder
    git checkout "$BUILDER_BRANCH"
    popd
    popd
fi

# Now call the build_cron.sh of the new pytorch/builder, which is more recent
# than the repo that this script exists in
"${NIGHTLIES_FOLDER}/builder/cron/build_cron.sh" "$@"
