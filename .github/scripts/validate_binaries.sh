if [[ ${MATRIX_PACKAGE_TYPE} == "libtorch" ]]; then
    curl ${MATRIX_INSTALLATION} -o libtorch.zip
    unzip libtorch.zip
else
    # Special case Pypi installation package, only applicable to linux nightly CUDA 11.7 builds, wheel package
    if [[ ${TARGET_OS} == 'linux' && ${MATRIX_GPU_ARCH_VERSION} == '11.7' && ${MATRIX_PACKAGE_TYPE} == 'manywheel' && ${MATRIX_CHANNEL} != 'nightly' ]]; then
        conda create -yp ${ENV_NAME}_pypi python=${MATRIX_PYTHON_VERSION} numpy ffmpeg
        INSTALLATION_PYPI=${MATRIX_INSTALLATION/"cu117"/"cu117_pypi_cudnn"}
        INSTALLATION_PYPI=${INSTALLATION_PYPI/"torchvision torchaudio"/""}
        INSTALLATION_PYPI=${INSTALLATION_PYPI/"index-url"/"extra-index-url"}
        conda run -p ${ENV_NAME}_pypi ${INSTALLATION_PYPI}
        conda run -p ${ENV_NAME}_pypi python ./test/smoke_test/smoke_test.py --package torchonly
        conda deactivate
        conda env remove -p ${ENV_NAME}_pypi
    fi

    # Please note ffmpeg is required for torchaudio, see https://github.com/pytorch/pytorch/issues/96159
    conda create -y -n ${ENV_NAME} python=${MATRIX_PYTHON_VERSION} numpy ffmpeg
    conda activate ${ENV_NAME}
    INSTALLATION=${MATRIX_INSTALLATION/"conda install"/"conda install -y"}
    INSTALLATION=${INSTALLATION/"torchvision torchaudio"/""}
    eval $INSTALLATION

    if [[ ${TARGET_OS} == 'linux' ]]; then
        export CONDA_LIBRARY_PATH="$(dirname $(which python))/../lib"
        export LD_LIBRARY_PATH=$CONDA_LIBRARY_PATH:$LD_LIBRARY_PATH
        ${PWD}/check_binary.sh
    fi

    python  ./test/smoke_test/smoke_test.py --package torchonly
    conda deactivate
    conda env remove -n ${ENV_NAME}
fi
