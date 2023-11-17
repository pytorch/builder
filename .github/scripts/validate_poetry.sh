
conda create -y -n ${ENV_NAME}_poetry python=${MATRIX_PYTHON_VERSION} numpy ffmpeg
conda activate ${ENV_NAME}_poetry
curl -sSL https://install.python-poetry.org | python3 - --git https://github.com/python-poetry/poetry.git@master
export PATH="/root/.local/bin:$PATH"

poetry --version
poetry new test_poetry
cd test_poetry

TEST_SUFFIX=""
if [[ ${TORCH_ONLY} == 'true' ]]; then
    TEST_SUFFIX=" --package torchonly"
fi

RELEASE_SUFFIX=""
# if RELESE version is passed as parameter - install speific version
if [[ ! -z ${RELEASE_VERSION} ]]; then
    RELEASE_SUFFIX="@${RELEASE_VERSION}"
fi

# Installing poetry from our custom repo. We need to configure it before use and disable authentication
export PYTHON_KEYRING_BACKEND=keyring.backends.null.Keyring
poetry source add --priority=explicit pytorch "https://download.pytorch.org/whl/${MATRIX_DESIRED_CUDA}"
if [[ ${TORCH_ONLY} == 'true' ]]; then
    poetry --quiet add torch${RELEASE_SUFFIX}
else
    poetry --quiet add --source pytorch torch${RELEASE_SUFFIX} torchaudio torchvision
fi

python ../test/smoke_test/smoke_test.py ${TEST_SUFFIX} --runtime-error-check disabled
conda deactivate
conda env remove -p ${ENV_NAME}_poetry
cd ..
