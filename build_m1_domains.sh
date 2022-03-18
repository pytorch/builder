#!/bin/zsh
# Script used to build domain libraries wheels for M1
source ~/miniconda3/etc/profile.d/conda.sh
set -ex
TORCH_VERSION=1.11.0
TORCHVISION_VERSION=0.12.0
TORCHAUDIO_VERSION=0.11.0
TORCHTEXT_VERSION=0.12.0

build_wheels() {
  PYTHON_VERSION=$1
  PY_VERSION=${PYTHON_VERSION/.}
  conda create -yn whl-py${PY_VERSION}-torch-${TORCH_VERSION} python=${PYTHON_VERSION} numpy libpng openjpeg wheel pkg-config
  conda activate whl-py${PY_VERSION}-torch-${TORCH_VERSION}
  python3 -mpip install torch --extra-index-url=https://download.pytorch.org/whl/test torch==${TORCH_VERSION}
  python3 -mpip install delocate

  pushd ~/git/pytorch/vision
  git checkout release/${TORCHVISION_VERSION%.*}
  rm -rf build
  BUILD_VERSION=${TORCHVISION_VERSION} python3 setup.py bdist_wheel
  WHL_NAME=torchvision-${TORCHVISION_VERSION}-cp${PY_VERSION}-cp${PY_VERSION}-macosx_11_0_arm64.whl
  DYLD_FALLBACK_LIBRARY_PATH="$(dirname $(dirname $(which python)))/lib" delocate-wheel -v --ignore-missing-dependencies dist/${WHL_NAME}
  python3 -mpip install dist/${WHL_NAME}
  popd

  pushd ~/git/pytorch/audio
  git checkout release/${TORCHAUDIO_VERSION%.*}
  rm -rf build
  BUILD_VERSION=${TORCHAUDIO_VERSION} python3 setup.py bdist_wheel
  WHL_NAME=torchaudio-${TORCHAUDIO_VERSION}-cp${PY_VERSION}-cp${PY_VERSION}-macosx_11_0_arm64.whl
  python3 -mpip install dist/${WHL_NAME}
  popd

  pushd ~/git/pytorch/text
  git checkout release/${TORCHTEXT_VERSION%.*}
  rm -rf build
  BUILD_VERSION=${TORCHTEXT_VERSION} python3 setup.py bdist_wheel
  WHL_NAME=torchtext-${TORCHTEXT_VERSION}-cp${PY_VERSION}-cp${PY_VERSION}-macosx_11_0_arm64.whl
  python3 -mpip install dist/${WHL_NAME}
  popd

  python -c "import torch;import torchvision;print('Is torchvision useable?', all(x is not None for x in [torch.ops.image.decode_png, torch.ops.torchvision.roi_align]))"
  python -c "import torch;import torchaudio;torchaudio.set_audio_backend('sox_io')"
}

build_conda() {
  PYTHON_VERSION=$1
  PY_VERSION=${PYTHON_VERSION/.}
  export CONDA_PYTORCH_BUILD_CONSTRAINT="- pytorch==$TORCH_VERSION.arm64"
  export CONDA_PYTORCH_CONSTRAINT="- pytorch==$TORCH_VERSION.arm64"
  pushd ~/git/pytorch/vision
  export SOURCE_ROOT_DIR=$(pwd)
  export BUILD_VERSION=${TORCHVISION_VERSION}
  export CU_VERSION="cpu"
  conda build --check --no-anaconda-upload -c pytorch packaging/torchvision --python ${PYTHON_VERSION}
  #conda build --no-anaconda-upload -c pytorch packaging/torchvision --python ${PYTHON_VERSION}
  #conda debug --no-anaconda-upload -c pytorch packaging/torchvision --python ${PYTHON_VERSION}
  popd
}

build_conda 3.9

