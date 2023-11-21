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
    pip3 install torch${RELEASE_SUFFIX}
else
    pip3 install torch${RELEASE_SUFFIX} torchvision torchaudio
fi

python ./test/smoke_test/smoke_test.py ${TEST_SUFFIX} --runtime-error-check disabled
conda deactivate
conda env remove -p ${ENV_NAME}_pypi
