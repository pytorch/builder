set -ex

conda create -y -n ${ENV_NAME} python=${DESIRED_PYTHON} numpy pillow
conda activate ${ENV_NAME}
export CONDA_LIBRARY_PATH="$(dirname $(which python))/../lib"
export LD_LIBRARY_PATH=$CONDA_LIBRARY_PATH:$LD_LIBRARY_PATH

if [[ ${PACKAGE_TYPE} == "libtorch" ]]; then
    curl ${INSTALLATION} -o libtorch.zip
    unzip libtorch.zip
else
    INSTALLATION=${INSTALLATION/"conda install"/"conda install -y"}
    eval $INSTALLATION
    python  ./test/smoke_test/smoke_test.py
    ${PWD}/check_binary.sh
fi
