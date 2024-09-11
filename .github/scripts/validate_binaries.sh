if [[ ${MATRIX_PACKAGE_TYPE} == "libtorch" ]]; then
    curl ${MATRIX_INSTALLATION} -o libtorch.zip
    unzip libtorch.zip
else

    export PYTHON_RUN="python3"
    if [[ ${TARGET_OS} == 'windows' ]]; then
        export PYTHON_RUN="python"
    fi

    if [[ ${TARGET_OS} == 'macos-arm64' ]]; then
        conda update -y -n base -c defaults conda
    elif [[ ${TARGET_OS} != 'linux-aarch64' ]]; then
        # Conda pinned see issue: https://github.com/ContinuumIO/anaconda-issues/issues/13350
        conda install -y conda=23.11.0
    fi
    # Please note ffmpeg is required for torchaudio, see https://github.com/pytorch/pytorch/issues/96159
    conda create -y -n ${ENV_NAME} python=${MATRIX_PYTHON_VERSION} ffmpeg
    conda activate ${ENV_NAME}
    pip3 install numpy==2.1.1 --force-reinstall
    INSTALLATION=${MATRIX_INSTALLATION/"conda install"/"conda install -y"}
    TEST_SUFFIX=""

    # force-reinstall: latest version of packages are reinstalled
    if [[ ${USE_FORCE_REINSTALL} == 'true' ]]; then
        INSTALLATION=${INSTALLATION/"pip3 install"/"pip3 install --force-reinstall"}
    fi
    # extra-index-url: extra dependencies are downloaded from pypi
    if [[ ${USE_EXTRA_INDEX_URL} == 'true' ]]; then
        INSTALLATION=${INSTALLATION/"--index-url"/"--extra-index-url"}
    fi

    if [[ ${TORCH_ONLY} == 'true' ]]; then
        INSTALLATION=${INSTALLATION/"torchvision torchaudio"/""}
        TEST_SUFFIX=" --package torchonly"
    fi

    # if RELESE version is passed as parameter - install speific version
    if [[ ! -z ${RELEASE_VERSION} ]]; then
          INSTALLATION=${INSTALLATION/"torch "/"torch==${RELEASE_VERSION} "}
          INSTALLATION=${INSTALLATION/"-y pytorch "/"-y pytorch==${RELEASE_VERSION} "}
          INSTALLATION=${INSTALLATION/"::pytorch "/"::pytorch==${RELEASE_VERSION} "}

        if [[ ${USE_VERSION_SET} == 'true' ]]; then
          INSTALLATION=${INSTALLATION/"torchvision "/"torchvision==${VISION_RELEASE_VERSION} "}
          INSTALLATION=${INSTALLATION/"torchaudio "/"torchaudio==${AUDIO_RELEASE_VERSION} "}
        fi
    fi

    export OLD_PATH=${PATH}
    # Workaround macos-arm64 runners. Issue: https://github.com/pytorch/test-infra/issues/4342
    if [[ ${TARGET_OS} == 'macos-arm64' ]]; then
        export PATH="${CONDA_PREFIX}/bin:${PATH}"
    fi

    # Make sure we remove previous installation if it exists
    if [[ ${MATRIX_PACKAGE_TYPE} == 'wheel' ]]; then
        pip3 uninstall -y torch torchaudio torchvision
    fi
    eval $INSTALLATION

    if [[ ${TARGET_OS} == 'linux' ]]; then
        export CONDA_LIBRARY_PATH="$(dirname $(which python))/../lib"
        export LD_LIBRARY_PATH=$CONDA_LIBRARY_PATH:$LD_LIBRARY_PATH
        ${PWD}/check_binary.sh
    fi

     # We are only interested in CUDA tests and Python 3.8-3.11. Not all requirement libraries are available for 3.12 yet.
    if [[ ${INCLUDE_TEST_OPS:-} == 'true' &&  ${MATRIX_GPU_ARCH_TYPE} == 'cuda' && ${MATRIX_PYTHON_VERSION} != "3.12" ]]; then
        source ./.github/scripts/validate_test_ops.sh
    fi

    # Regular smoke test
    ${PYTHON_RUN}  ./test/smoke_test/smoke_test.py ${TEST_SUFFIX}
    # For pip install also test with numpy 2.0.0 for python 3.8 or above
    if [[ ${MATRIX_PACKAGE_TYPE} == 'wheel' && ${MATRIX_PYTHON_VERSION} != "3.8" ]]; then
        pip3 install numpy==2.0.0 --force-reinstall
        ${PYTHON_RUN}  ./test/smoke_test/smoke_test.py ${TEST_SUFFIX}
    fi


    if [[ ${TARGET_OS} == 'macos-arm64' ]]; then
        export PATH=${OLD_PATH}
    fi

    # Use case CUDA_VISIBLE_DEVICES: https://github.com/pytorch/pytorch/issues/128819
    if [[ ${MATRIX_GPU_ARCH_TYPE} == 'cuda' ]]; then
        python -c "import torch;import os;print(torch.cuda.device_count(), torch.__version__);os.environ['CUDA_VISIBLE_DEVICES']='0';print(torch.empty(2, device='cuda'))"
    fi

    # this is optional step
    if [[ ${TARGET_OS} != linux*  ]]; then
        conda deactivate
        conda env remove -n ${ENV_NAME}
    fi

fi
