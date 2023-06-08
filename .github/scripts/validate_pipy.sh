conda create -yp ${ENV_NAME}_pypi python=${MATRIX_PYTHON_VERSION} numpy ffmpeg

if [[ ${MATRIX_CHANNEL} != "release" ]]; then
    conda run -p ${ENV_NAME}_pypi pip3 install --pre torch --index-url "https://download.pytorch.org/whl/${MATRIX_CHANNEL}/${MATRIX_DESIRED_CUDA}_pypi_cudnn"
    conda run -p ${ENV_NAME}_pypi pip3 install --pre torchvision torchaudio --index-url "https://download.pytorch.org/whl/${MATRIX_CHANNEL}/${MATRIX_DESIRED_CUDA}"
else
    conda run -p ${ENV_NAME}_pypi pip3 install torch torchvision torchaudio
fi

conda run -p ${ENV_NAME}_pypi python ./test/smoke_test/smoke_test.py
conda deactivate
conda env remove -p ${ENV_NAME}_pypi
