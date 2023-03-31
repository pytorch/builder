if [[ ${MATRIX_PACKAGE_TYPE} == "libtorch" ]]; then
    curl ${MATRIX_INSTALLATION} -o libtorch.zip
    unzip libtorch.zip
else
    if [[ ${MATRIX_INSTALLATION}=='pip3 install torch torchvision torchaudio' && ${MATRIX_GPU_ARCH_TYPE} == 'cpu' ]]; then
        MATRIX_INSTALLATION='pip3 install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu'
    fi
    if [[ ${MATRIX_INSTALLATION}=='pip3 install torch torchvision torchaudio' && ${MATRIX_GPU_ARCH_VERSION} == '11.7' ]]; then
        MATRIX_INSTALLATION='pip3 install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu117'
    fi

    #special case for Python 3.11
    if [[ ${MATRIX_PYTHON_VERSION} == '3.11' && ${MATRIX_PACKAGE_TYPE} == 'manywheel' ]]; then
        conda create -y -n ${ENV_NAME} python=${MATRIX_PYTHON_VERSION}
        conda activate ${ENV_NAME}

        #INSTALLATION=${MATRIX_INSTALLATION/"-c pytorch"/"-c malfet -c pytorch"}
        #INSTALLATION=${INSTALLATION/"pytorch-cuda"/"pytorch::pytorch-cuda"}
        INSTALLATION=${MATRIX_INSTALLATION/"conda install"/"conda install -y"}

        export installation_log=$(eval $INSTALLATION)
        export filedownload=$(echo "$installation_log" | grep Downloading.*torchaudio.* | grep -Eio '\bhttps://.*whl\b')
        echo $filedownload
        curl -O ${filedownload}
        unzip -o torchaudio-2.0.*
        export textdist=$(ls | grep -Ei "torchaudio.*dist-info")
        while [ ! -f ./${textdist}/METADATA ]; do sleep 1; done
        export match=$(cat ./${textdist}/METADATA | grep "torch (==2.0.0")
        echo $match
        [[ -z "$match" ]] && { echo "Torch is not Pinned in Audio!!!" ; exit 1; }

        export filedownload=$(echo "$installation_log" | grep Downloading.*torchvision.* | grep -Eio '\bhttps://.*whl\b')
        echo $filedownload
        curl -O ${filedownload}
        unzip -o torchvision-0.15.*
        export textdist=$(ls | grep -Ei "torchvision.*dist-info")
        while [ ! -f ./${textdist}/METADATA ]; do sleep 1; done
        export match=$(cat ./${textdist}/METADATA | grep "torch (==2.0.0")
        echo $match
        [[ -z "$match" ]] && { echo "Torch is not Pinned in torchvision!!!" ; exit 1; }
        python ./test/smoke_test/smoke_test.py
        conda deactivate
        conda env remove -n ${ENV_NAME}
    else

        # Please note ffmpeg is required for torchaudio, see https://github.com/pytorch/pytorch/issues/96159
        conda create -y -n ${ENV_NAME} python=${MATRIX_PYTHON_VERSION} ffmpeg
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
            export match=$(cat ./${textdist}/METADATA | grep "torch (==2.0.0")
            echo $match
            [[ -z "$match" ]] && { echo "Torch is not Pinned in Audio!!!" ; exit 1; }

            export filedownload=$(echo "$installation_log" | grep Downloading.*torchvision.* | grep -Eio '\bhttps://.*whl\b')
            echo $filedownload
            curl -O ${filedownload}
            unzip -o torchvision-0.15.*
            export textdist=$(ls | grep -Ei "torchvision.*dist-info")
            while [ ! -f ./${textdist}/METADATA ]; do sleep 1; done
            export match=$(cat ./${textdist}/METADATA | grep "torch (==2.0.0")
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
