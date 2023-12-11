conda create -yn ${ENV_NAME}_pypi python=${MATRIX_PYTHON_VERSION} numpy ffmpeg
conda activate ${ENV_NAME}_pypi

TEST_SUFFIX=""
RELEASE_SUFFIX=""
# if RELESE version is passed as parameter - install speific version
if [[ ! -z ${RELEASE_VERSION} ]]; then
    RELEASE_SUFFIX="==${RELEASE_VERSION}"
fi

if [[ ${TORCH_ONLY} == 'true' ]]; then
    TEST_SUFFIX=" --package torchonly"
    pip3 install --pre torch${RELEASE_SUFFIX} --extra-index-url "https://download.pytorch.org/whl/${MATRIX_CHANNEL}/${MATRIX_DESIRED_CUDA}_pypi_cudnn"
else
    if [[ ${MATRIX_CHANNEL} != "release" ]]; then
        pip3 install --pre torch${RELEASE_SUFFIX} --extra-index-url "https://download.pytorch.org/whl/${MATRIX_CHANNEL}/${MATRIX_DESIRED_CUDA}_pypi_cudnn"
        pip3 install --pre torchvision==0.16.2 torchaudio==2.1.2 --extra-index-url "https://download.pytorch.org/whl/${MATRIX_CHANNEL}/${MATRIX_DESIRED_CUDA}"
    else
        pip3 install torch${RELEASE_SUFFIX}  torchvision torchaudio
    fi
fi

python ./test/smoke_test/smoke_test.py ${TEST_SUFFIX} --runtime-error-check disabled
conda deactivate
conda env remove -p ${ENV_NAME}_pypi
