#!/usr/bin/env bash
if [[ -x "/remote/anaconda_token" ]]; then
    . /remote/anaconda_token || true
fi

set -ex

# Defined a portable sed that should work on both mac and linux
if [ "$(uname)" == 'Darwin' ]; then
  portable_sed="sed -E -i ''"
else
  portable_sed='sed --regexp-extended -i'
fi

echo "Building cuda version $1 and pytorch version: $2 build_number: $3"
desired_cuda="$1"
build_version="$2"
build_number="$3"

# setup.py is hardcoded to use these variables
export PYTORCH_BUILD_VERSION=$build_version
export PYTORCH_BUILD_NUMBER=$build_number

if [[ "$build_version" == "nightly" ]]; then
    export PYTORCH_BUILD_VERSION="$(date +"%Y.%m.%d")"
fi


# This is the channel that finished packages will be uploaded to
if [[ -z "$ANACONDA_USER" ]]; then
    ANACONDA_USER=soumith
fi

# Token needed to upload to the conda channel above
if [ -z "$ANACONDA_TOKEN" ]; then
    echo "ANACONDA_TOKEN is unset. Please set it in your environment before running this script";
fi

# Don't upload the packages until we've verified that they're correct
conda config --set anaconda_upload no

# Keep an array of cmake variables to add to
if [[ -z "$CMAKE_ARGS" ]]; then
    # These are passed to tools/build_pytorch_libs.sh::build()
    CMAKE_ARGS=()
fi
if [[ -z "$EXTRA_CAFFE2_CMAKE_FLAGS" ]]; then
    # These are passed to tools/build_pytorch_libs.sh::build_caffe2()
    EXTRA_CAFFE2_CMAKE_FLAGS=()
fi

# Build for a specified Python, or if none were given then all of them
if [[ -z "$DESIRED_PYTHON" ]]; then
    DESIRED_PYTHON=('2.7' '3.5' '3.6' '3.7')
fi
echo "Will build for all Pythons: ${DESIRED_PYTHON[@]}"
echo "Will build for all CUDA versions: ${desired_cuda[@]}"


# Determine which build folder to use, if not given it directly
if [[ -n "$TORCH_CONDA_BUILD_FOLDER" ]]; then
    build_folder="$TORCH_CONDA_BUILD_FOLDER"
else
    if [[ "$OSTYPE" == 'darwin'* || "$desired_cuda" == '90' ]]; then
        build_folder='pytorch'
    elif [[ "$desired_cuda" == 'cpu' ]]; then
        build_folder='pytorch-cpu'
    else
        build_folder="pytorch-$desired_cuda"
    fi
    build_folder="$build_folder-$build_version"
fi
echo "Using conda-build folder $build_folder"

# Switch the CUDA version that /usr/local/cuda points to
if [[ "$OSTYPE" == "darwin"* ]]; then
    export CUDA_VERSION="0.0"
    export CUDNN_VERSION="0.0"
elif [[ "$desired_cuda" != 'cpu' ]]; then
    echo "Switching to CUDA version ${desired_cuda:0:1}.${desired_cuda:1:1}"
    . ./switch_cuda_version.sh "${desired_cuda:0:1}.${desired_cuda:1:1}"
    $portable_sed "s/cudatoolkit =[0-9]/cudatoolkit =${desired_cuda:0:1}/g" "$build_folder/meta.yaml"
fi
if [[ "$desired_cuda" == 92 ]]; then
    # ATen tests can't build with CUDA 9.2 and the old compiler used here
    EXTRA_CAFFE2_CMAKE_FLAGS+=("-DATEN_NO_TEST=ON")
fi
    

# Alter the meta.yaml to use passed in Github repo/branch
if [[ -n "$GITHUB_ORG" ]]; then
    $portable_sed "s#git_url:.*#git_url: https://github.com/$GITHUB_ORG/pytorch#g" "$build_folder/meta.yaml"
fi
if [[ -n "$PYTORCH_BRANCH" ]]; then
    $portable_sed "s#git_rev:.*#git_rev: $PYTORCH_BRANCH#g" "$build_folder/meta.yaml"
fi

# Loop through all Python versions to build a package for each
for py_ver in "${DESIRED_PYTHON[@]}"; do
    echo "Build $build_folder for Python version $py_ver"
    time CMAKE_ARGS=${CMAKE_ARGS[@]} \
         EXTRA_CAFFE2_CMAKE_FLAGS=${EXTRA_CAFFE2_CMAKE_FLAGS[@]} \
         conda build -c "$ANACONDA_USER" \
                     --no-anaconda-upload \
                     --python "$py_ver" \
                     "$build_folder"
done

echo "All builds succeeded, uploading binaries"

set +e

# anaconda -t $ANACONDA_TOKEN upload --user $ANACONDA_USER $(conda build -c $ANACONDA_USER --python 2.7 pytorch-$build_version --output)
# anaconda -t $ANACONDA_TOKEN upload --user $ANACONDA_USER $(conda build -c $ANACONDA_USER --python 3.5 pytorch-$build_version --output)
# anaconda -t $ANACONDA_TOKEN upload --user $ANACONDA_USER $(conda build -c $ANACONDA_USER --python 3.6 pytorch-$build_version --output)

unset PYTORCH_BUILD_VERSION
unset PYTORCH_BUILD_NUMBER
