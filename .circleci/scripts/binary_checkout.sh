#!/bin/bash
# Derived from https://github.com/pytorch/pytorch/blob/2c7df1360aa17d4a6d6726998eede3671bcb36ee/.circleci/scripts/binary_populate_env.sh

set -eux -o pipefail

retry () {
    $*  || (sleep 1 && $*) || (sleep 2 && $*) || (sleep 4 && $*) || (sleep 8 && $*)
}


# This step runs on multiple executors with different envfile locations
if [[ "$OSTYPE" == "msys" ]]; then
  # windows executor (builds and tests)
  rm -rf /c/w
  ln -s "${HOME}" /c/w
  WORK_DIR="/c/w"
elif [[ -d "/home/circleci/project" ]]; then
  # machine executor (binary tests)
  WORK_DIR="${HOME}/project"
else
  # macos executor (builds and tests)
  # docker executor (binary builds)
  WORK_DIR="${HOME}"
fi

if [[ "$OSTYPE" == "msys" ]]; then
  # We need to make the paths as short as possible on Windows
  PYTORCH_ROOT="$WORK_DIR/p"
  BUILDER_ROOT="$WORK_DIR/b"
else
  PYTORCH_ROOT="$WORK_DIR/pytorch"
  BUILDER_ROOT="$WORK_DIR/builder"
fi

# Persist these variables for the subsequent steps
echo "export WORK_DIR=${WORK_DIR}" >> ${BASH_ENV}
echo "export PYTORCH_ROOT=${PYTORCH_ROOT}" >> ${BASH_ENV}
echo "export BUILDER_ROOT=${BUILDER_ROOT}" >> ${BASH_ENV}

# Clone the Pytorch branch
retry git clone --depth 1 https://github.com/pytorch/pytorch.git "$PYTORCH_ROOT"
# Removed checking out pytorch/pytorch using CIRCLE_PR_NUMBER and CIRCLE_SHA1 as
# those environment variables are tied to the host repo where the build is being
# triggered.
retry git submodule update --init --recursive
pushd "$PYTORCH_ROOT"
echo "Using Pytorch from "
git --no-pager log --max-count 1
popd

# Clone the Builder master repo
retry git clone -q https://github.com/pytorch/builder.git "$BUILDER_ROOT"
pushd "$BUILDER_ROOT"
if [[ -n "${CIRCLE_SHA1:-}" ]]; then
  # Check out a specific commit (typically the latest) from pytorch/builder
  git reset --hard "${CIRCLE_SHA1}"
  git checkout -q -B main
fi
echo "Using builder from "
git --no-pager log --max-count 1
popd
