#!/usr/bin/env bash
if [[ -x "/remote/anaconda_token" ]]; then
    . /remote/anaconda_token || true
fi

set -ex

# Defined a portable sed that should work on both mac and linux
if [[ "$OSTYPE" == "darwin"* ]]; then
  portable_sed="sed -E -i ''"
else
  portable_sed='sed --regexp-extended -i'
fi

if [ "$#" -ne 3 ]; then
    echo "Illegal number of parameters. Pass cuda version, pytorch version, build number"
    echo "CUDA version should be Mm with no dot, e.g. '80'"
    echo "DESIRED_PYTHON should be M.m, e.g. '2.7'"
    exit 1
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
    if [[ -z "$PYTORCH_BRANCH" ]]; then
	PYTORCH_BRANCH='master'
    fi
else
    PYTORCH_BRANCH="v$build_version"
fi

# Don't upload the packages until we've verified that they're correct
conda config --set anaconda_upload no

# Fill in missing env variables
if [ -z "$ANACONDA_TOKEN" ]; then
    # Token needed to upload to the conda channel above
    echo "ANACONDA_TOKEN is unset. Please set it in your environment before running this script";
fi
if [[ -z "$ANACONDA_USER" ]]; then
    # This is the channel that finished packages will be uploaded to
    ANACONDA_USER=soumith
fi
if [[ -z "$GITHUB_ORG" ]]; then
    GITHUB_ORG='pytorch'
fi
if [[ -z "$CMAKE_ARGS" ]]; then
    # These are passed to tools/build_pytorch_libs.sh::build()
    CMAKE_ARGS=()
fi
if [[ -z "$EXTRA_CAFFE2_CMAKE_FLAGS" ]]; then
    # These are passed to tools/build_pytorch_libs.sh::build_caffe2()
    EXTRA_CAFFE2_CMAKE_FLAGS=()
fi
if [[ -z "$DESIRED_PYTHON" ]]; then
    DESIRED_PYTHON=('2.7' '3.5' '3.6' '3.7')
fi
if [[ "$OSTYPE" == "darwin"* ]]; then
    DEVELOPER_DIR=/Applications/Xcode9.app/Contents/Developer
fi
if [[ "$desired_cuda" == 'cpu' ]]; then
    cpu_only=1
else
    # Switch desired_cuda to be M.m to be consistent with other scripts in
    # pytorch/builder
    cuda_nodot="$desired_cuda"
    desired_cuda="${desired_cuda:0:1}.${desired_cuda:1:1}"
fi


echo "Will build for all Pythons: ${DESIRED_PYTHON[@]}"
echo "Will build for CUDA version: ${desired_cuda}"

# Determine which build folder to use, if not given it directly
if [[ -n "$TORCH_CONDA_BUILD_FOLDER" ]]; then
    build_folder="$TORCH_CONDA_BUILD_FOLDER"
else
    if [[ "$OSTYPE" == 'darwin'* || "$desired_cuda" == '9.0' ]]; then
        build_folder='pytorch'
    elif [[ -n "$cpu_only" ]]; then
        build_folder='pytorch-cpu'
    else
        build_folder="pytorch-$cuda_nodot"
    fi
    build_folder="$build_folder-$build_version"
fi
meta_yaml="$build_folder/meta.yaml"
echo "Using conda-build folder $build_folder"

# Clone the Pytorch repo, so that we can call run_test.py in it
pytorch_rootdir="$(pwd)/root_${GITHUB_ORG}pytorch${PYTORCH_BRANCH}"
rm -rf "$pytorch_rootdir"
git clone --recursive "https://github.com/$GITHUB_ORG/pytorch.git" "$pytorch_rootdir"
pushd "$pytorch_rootdir"
git checkout "$PYTORCH_BRANCH"
popd

# Switch between CPU or CUDA configerations
build_string_suffix="$PYTORCH_BUILD_NUMBER"
if [[ -n "$cpu_only" ]]; then
    export NO_CUDA=1
    export CUDA_VERSION="0.0"
    export CUDNN_VERSION="0.0"
    if [[ "$OSTYPE" != "darwin"* ]]; then
        build_string_suffix="cpu_${build_string_suffix}"
    fi
    $portable_sed "/magma-cuda.*/d" "$meta_yaml"
else
    # Switch the CUDA version that /usr/local/cuda points to. This script also
    # sets CUDA_VERSION and CUDNN_VERSION
    echo "Switching to CUDA version $desired_cuda"
    . ./switch_cuda_version.sh "$desired_cuda"
    build_string_suffix="cuda${CUDA_VERSION}_cudnn${CUDNN_VERSION}_${build_string_suffix}"
    if [[ "$desired_cuda" == '9.2' ]]; then
        # ATen tests can't build with CUDA 9.2 and the old compiler used here
        EXTRA_CAFFE2_CMAKE_FLAGS+=("-DATEN_NO_TEST=ON")
    fi
    ALLOW_DISTRIBUTED_TEST_ERRORS=1
fi

# Loop through all Python versions to build a package for each
for py_ver in "${DESIRED_PYTHON[@]}"; do
    build_string="py${py_ver}_${build_string_suffix}"
    folder_tag="${build_string}_$(date +'%Y%m%d')"

    # Create the conda package into this temporary folder. This is so we can find
    # the package afterwards, as there's no easy way to extract the final filename
    # from conda-build
    output_folder="out_$folder_tag"
    rm -rf "$output_folder"
    mkdir "$output_folder"

    # Build the package
    echo "Build $build_folder for Python version $py_ver"
    time CMAKE_ARGS=${CMAKE_ARGS[@]} \
         EXTRA_CAFFE2_CMAKE_FLAGS=${EXTRA_CAFFE2_CMAKE_FLAGS[@]} \
         PYTORCH_GITHUB_ROOT_DIR="$pytorch_rootdir" \
         PYTORCH_BUILD_STRING="$build_string" \
         PYTORCH_MAGMA_CUDA_VERSION="$cuda_nodot" \
         conda build -c "$ANACONDA_USER" \
                     --no-anaconda-upload \
                     --python "$py_ver" \
                     --output-folder "$output_folder" \
                     --no-test \
                     "$build_folder"

    # Create a new environment to test in
    # TODO these reqs are hardcoded for pytorch-nightly
    test_env="env_$folder_tag"
    conda create -yn "$test_env" python="$py_ver"
    source activate "$test_env"
    conda install -y numpy>=1.11 mkl>=2018 cffi ninja

    # Extract the package for testing
    ls -lah "$output_folder"
    built_package="$(find $output_folder/ -name '*pytorch*')"
    conda install -y "$built_package"

    # Run tests
    pushd "$pytorch_rootdir"
    if [[ -n "$RUN_TEST_PARAMS" ]]; then
        python test/run_test.py ${RUN_TEST_PARAMS[@]}
    elif [[ "$ALLOW_DISTRIBUTED_TEST_ERRORS" ]]; then
        python test/run_test.py -x distributed c10d
        # See manywheel/build_common.sh for why these are split
        set +e
        python test/run_test.py -i distributed c10d
        set -e
    else
        python test/run_test.py
    fi
    popd

    # TODO Upload the package

    # Clean up test folder
    source deactivate
    conda env remove -yn "$test_env"
    rm -rf "$output_folder"
done
rm -rf "$pytorch_rootdir"

unset PYTORCH_BUILD_VERSION
unset PYTORCH_BUILD_NUMBER
