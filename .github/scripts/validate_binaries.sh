if [[ ${MATRIX_PACKAGE_TYPE} == "libtorch" ]]; then
    curl ${MATRIX_INSTALLATION} -o libtorch.zip
    unzip libtorch.zip
else

    #special case for Python 3.11
    if [[ ${MATRIX_PYTHON_VERSION} == '3.11' ]]; then
        conda create -y -n ${ENV_NAME} python=${MATRIX_PYTHON_VERSION}
        conda activate ${ENV_NAME}

        INSTALLATION=${MATRIX_INSTALLATION/"-c pytorch"/"-c malfet -c pytorch"}
        INSTALLATION=${INSTALLATION/"pytorch-cuda"/"pytorch-${MATRIX_CHANNEL}::pytorch-cuda"}
        INSTALLATION=${INSTALLATION/"conda install"/"conda install -y"}

        eval $INSTALLATION
        python ./test/smoke_test/smoke_test.py
        conda deactivate
        conda env remove -n ${ENV_NAME}
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

        if [[ ${MATRIX_PACKAGE_TYPE} == 'manywheel' ]]; then
            export installation_log=$(eval $INSTALLATION)
            export filedownload=$(echo "$installation_log" | grep Downloading.*torchaudio.* | grep -Eio '\bhttps://.*whl\b')
            echo $filedownload
            curl -O ${filedownload}
            unzip -o torchaudio-2.0.*
            export textdist=$(ls | grep -Ei "torchaudio.*dist-info")
            while [ ! -f ./${textdist}/METADATA ]; do sleep 1; done
            export match=$(cat ./${textdist}/METADATA | grep "torch (==2.0.0)")
            echo $match
            [[ -z "$match" ]] && { echo "Torch is not Pinned in Audio!!!" ; exit 1; }

            export filedownload=$(echo "$installation_log" | grep Downloading.*torchvision.* | grep -Eio '\bhttps://.*whl\b')
            echo $filedownload
            curl -O ${filedownload}
            unzip -o torchvision-0.15.*
            export textdist=$(ls | grep -Ei "torchvision.*dist-info")
            while [ ! -f ./${textdist}/METADATA ]; do sleep 1; done
            export match=$(cat ./${textdist}/METADATA | grep "torch (==2.0.0)")
            echo $match
            [[ -z "$match" ]] && { echo "Torch is not Pinned in torchvision!!!" ; exit 1; }

        else
            eval $INSTALLATION
        fi

        if [[ ${TARGET_OS} == 'linux' ]]; then
            export CONDA_LIBRARY_PATH="$(dirname $(which python))/../lib"
            export LD_LIBRARY_PATH=$CONDA_LIBRARY_PATH:$LD_LIBRARY_PATH
            ${PWD}/check_binary.sh
        fi

        python  ./test/smoke_test/smoke_test.py
        conda deactivate
        conda env remove -n ${ENV_NAME}
    fi
fi
