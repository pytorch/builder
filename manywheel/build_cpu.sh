#!/usr/bin/env bash

set -ex

yum install -y zip

if [[ -z "$PYTORCH_BUILD_VERSION" ]]; then
    export PYTORCH_BUILD_VERSION=0.4.1
fi
if [[ -z "$PYTORCH_BUILD_NUMBER" ]]; then
    export PYTORCH_BUILD_NUMBER=2
fi
export TH_BINARY_BUILD=1
export NO_CUDA=1
export CMAKE_LIBRARY_PATH="/opt/intel/lib:/lib:$CMAKE_LIBRARY_PATH"
export CMAKE_INCLUDE_PATH="/opt/intel:$CMAKE_INCLUDE_PATH"

WHEELHOUSE_DIR="wheelhousecpu"

rm -rf /usr/local/cuda*

ANY_OLD_PYTHON="/opt/python/$(ls /opt/python | head -n1)"
export PATH=$ANY_OLD_PYTHON/bin:$PATH

# ########################################################
# # Compile wheels
# #######################################################
# clone pytorch source code
PYTORCH_DIR="/pytorch"
if [[ ! -d "$PYTORCH_DIR" ]]; then
    git clone https://github.com/pytorch/pytorch $PYTORCH_DIR
    pushd $PYTORCH_DIR
    if ! git checkout v${PYTORCH_BUILD_VERSION}; then
       git checkout tags/v${PYTORCH_BUILD_VERSION}
    fi
else
    # the pytorch dir will already be cloned and checked-out on jenkins jobs
    pushd $PYTORCH_DIR
fi
git submodule update --init --recursive

# compile
pip install -r requirements.txt
mkdir -p build
pushd build
python ../tools/build_libtorch.py
find .
popd

mkdir libtorch
cp -r build/lib libtorch/lib
mkdir libtorch/include
mkdir libtorch/bin

mkdir -p $WHEELHOUSE_DIR
zip -rq $WHEELHOUSE_DIR/torch-libtorch.whl libtorch

popd

#######################################################################
# ADD DEPENDENCIES INTO THE WHEEL
######################################################################

DEPS_LIST=(
    "/usr/lib64/libgomp.so.1"
)

DEPS_SONAME=(
    "libgomp.so.1"
)

mkdir -p /$WHEELHOUSE_DIR
cp $PYTORCH_DIR/$WHEELHOUSE_DIR/*.whl /$WHEELHOUSE_DIR
mkdir /tmp_dir
pushd /tmp_dir

for whl in /$WHEELHOUSE_DIR/*.whl; do
    rm -rf tmp
    mkdir -p tmp
    pushd tmp
    cp $whl .

    unzip -q $(basename $whl)
    rm -f $(basename $whl)

    pushd libtorch
    # copy over needed dependent .so files
    for filepath in "${DEPS_LIST[@]}"
    do
	filename=$(basename $filepath)
	destpath=lib/$filename
	if [[ "$filepath" != "$destpath" ]]; then
	    cp $filepath $destpath
	fi
    done

    # set RPATH of lib/ files to $ORIGIN
    find lib -maxdepth 1 -type f -name "*.so*" | while read sofile; do
	echo "Setting rpath of $sofile to " '$ORIGIN'
	patchelf --set-rpath '$ORIGIN' $sofile
	patchelf --print-rpath $sofile
    done

    popd

    # zip the wheel back up
    zip -rq $(basename $whl) build

    # replace original wheel
    rm -f $whl
    mv $(basename $whl) $whl
    popd
    rm -rf tmp
done

# Copy wheels to host machine for persistence after the docker
mkdir -p /remote/$WHEELHOUSE_DIR
cp /$WHEELHOUSE_DIR/*.whl /remote/$WHEELHOUSE_DIR/
