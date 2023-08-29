conda create -yp ${ENV_NAME}_pypi python=${MATRIX_PYTHON_VERSION} numpy ffmpeg

TEST_SUFFIX=""
if [[ ${TORCH_ONLY} == 'true' ]]; then
    TEST_SUFFIX=" --package torchonly"
    conda run -p ${ENV_NAME}_pypi pip install --pre torch --index-url "https://download.pytorch.org/whl/${MATRIX_CHANNEL}/${MATRIX_DESIRED_CUDA}_pypi_cudnn"
else
    if [[ ${MATRIX_CHANNEL} != "release" ]]; then
        conda run -p ${ENV_NAME}_pypi pip install --pre torch --index-url "https://download.pytorch.org/whl/${MATRIX_CHANNEL}/${MATRIX_DESIRED_CUDA}_pypi_cudnn"
        conda run -p ${ENV_NAME}_pypi pip install --pre torchvision torchaudio --index-url "https://download.pytorch.org/whl/${MATRIX_CHANNEL}/${MATRIX_DESIRED_CUDA}"
    else
        conda run -p ${ENV_NAME}_pypi pip install torch torchvision torchaudio
    fi
fi

conda run -p ${ENV_NAME}_pypi python ./test/smoke_test/smoke_test.py ${TEST_SUFFIX} --runtime-error-check disabled
conda deactivate
conda env remove -p ${ENV_NAME}_pypi
