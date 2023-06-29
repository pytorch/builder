if [[ ${MATRIX_PACKAGE_TYPE} == "libtorch" ]]; then
    curl ${MATRIX_INSTALLATION} -o libtorch.zip
    unzip libtorch.zip
else
    # Please note ffmpeg is required for torchaudio, see https://github.com/pytorch/pytorch/issues/96159
    conda create -y -n ${ENV_NAME} python=${MATRIX_PYTHON_VERSION} numpy ffmpeg
    conda activate ${ENV_NAME}
    INSTALLATION=${MATRIX_INSTALLATION/"conda install"/"conda install -y"}

    # Make sure we remove previous installation if it exists
    if [[ ${MATRIX_PACKAGE_TYPE} == 'wheel' ]]; then
        UNINSTALL=${INSTALLATION/"install"/"uninstall -y"}
        eval $UNINSTALL
    fi
    eval $INSTALLATION

    if [[ ${TARGET_OS} == 'linux' ]]; then
        export CONDA_LIBRARY_PATH="$(dirname $(which python))/../lib"
        export LD_LIBRARY_PATH=$CONDA_LIBRARY_PATH:$LD_LIBRARY_PATH
        ${PWD}/check_binary.sh
    fi

    python  ./test/smoke_test/smoke_test.py
    conda deactivate
    conda env remove -n ${ENV_NAME}
fi
