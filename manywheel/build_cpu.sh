#!/usr/bin/env bash

set -ex

echo HERE I AM

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

# Build for given Python versions, or for all in /opt/python if none given
if [[ -z "$DESIRED_PYTHON" ]]; then
    pushd /opt/python
    DESIRED_PYTHON=(*/)
    popd
fi
python_installations=()
for desired_py in "${DESIRED_PYTHON[@]}"; do
    python_installations+=("/opt/python/$desired_py")
    if [[ ! -d "/opt/python/$desired_py" ]]; then
        echo "Error: Given Python $desired_py is not in /opt/python"
        echo "All array elements of env variable DESIRED_PYTHON must be"
        echo "valid Python installations under /opt/python"
        exit 1
    fi
done
echo "Will build for all Pythons versions: ${DESIRED_PYTHON[@]}"

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
python build_libtorch.py
find build
zip -rq $WHEELHOUSE_DIR/libtorch.whl build

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

for whl in /$WHEELHOUSE_DIR/torch*linux*.whl; do
    rm -rf tmp
    mkdir -p tmp
    cd tmp
    cp $whl .

    unzip -q $(basename $whl)
    rm -f $(basename $whl)

    # copy over needed dependent .so files over and tag them with their hash
    patched=()
    for filepath in "${DEPS_LIST[@]}"
    do
	filename=$(basename $filepath)
	destpath=torch/lib/$filename
	if [[ "$filepath" != "$destpath" ]]; then
	    cp $filepath $destpath
	fi

	patchedpath=$(fname_with_sha256 $destpath)
	patchedname=$(basename $patchedpath)
	if [[ "$destpath" != "$patchedpath" ]]; then
	    mv $destpath $patchedpath
	fi
	patched+=("$patchedname")
	echo "Copied $filepath to $patchedpath"
    done

    # set RPATH of _C.so and similar to $ORIGIN, $ORIGIN/lib
    find torch -maxdepth 1 -type f -name "*.so*" | while read sofile; do
	echo "Setting rpath of $sofile to " '$ORIGIN:$ORIGIN/lib'
	patchelf --set-rpath '$ORIGIN:$ORIGIN/lib' $sofile
	patchelf --print-rpath $sofile
    done

    # set RPATH of lib/ files to $ORIGIN
    find torch/lib -maxdepth 1 -type f -name "*.so*" | while read sofile; do
	echo "Setting rpath of $sofile to " '$ORIGIN'
	patchelf --set-rpath '$ORIGIN' $sofile
	patchelf --print-rpath $sofile
    done

    # zip up the wheel back
    zip -rq $(basename $whl) torch*

    # replace original wheel
    rm -f $whl
    mv $(basename $whl) $whl
    cd ..
    rm -rf tmp
done

# Take the actual package name. Note how this always works because pip converts
# - to _ in names.
pushd /$WHEELHOUSE_DIR
built_wheels=(torch*.whl)
IFS='-' read -r package_name some_unused_variable <<< "${built_wheels[0]}"
echo "Expecting the built wheels to all be called '$package_name'"
popd

# Copy wheels to host machine for persistence after the docker
mkdir -p /remote/$WHEELHOUSE_DIR
cp /$WHEELHOUSE_DIR/torch*.whl /remote/$WHEELHOUSE_DIR/

# remove stuff before testing
rm -rf /opt/rh
