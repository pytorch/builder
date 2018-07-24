#!/usr/bin/env bash

export CMAKE_LIBRARY_PATH=$PREFIX/lib:$PREFIX/include:$CMAKE_LIBRARY_PATH
export CMAKE_PREFIX_PATH=$PREFIX
# compile for Kepler, Kepler+Tesla, Maxwell, Volta
export PYTORCH_BUILD_VERSION=$PKG_VERSION
export PYTORCH_BUILD_NUMBER=$PKG_BUILDNUM
export TORCH_CUDA_ARCH_LIST="3.5;5.0+PTX;6.0;6.1;7.0"
export TORCH_NVCC_FLAGS="-Xfatbin -compress-all"
export NCCL_ROOT_DIR=/usr/local/cuda
export TH_BINARY_BUILD=1
export USE_STATIC_CUDNN=1
export USE_STATIC_NCCL=1
export ATEN_STATIC_CUDA=1
export USE_CUDA_STATIC_LINK=1

fname_with_sha256() {
    HASH=$(sha256sum $1 | cut -c1-8)
    DIRNAME=$(dirname $1)
    BASENAME=$(basename $1)
    if [[ $BASENAME == "libnvrtc-builtins.so" ]]; then
	echo $1
    else
	INITNAME=$(echo $BASENAME | cut -f1 -d".")
	ENDNAME=$(echo $BASENAME | cut -f 2- -d".")
	echo "$DIRNAME/$INITNAME-$HASH.$ENDNAME"
    fi
}

DEPS_LIST=(
    "/usr/local/cuda/lib64/libcudart.so.9.2"
    "/usr/local/cuda/lib64/libnvToolsExt.so.1"
    "/usr/local/cuda/lib64/libnvrtc.so.9.2"
    "/usr/local/cuda/lib64/libnvrtc-builtins.so"
)

DEPS_SONAME=(
    "libcudart.so.9.2"
    "libnvToolsExt.so.1"
    "libnvrtc.so.9.2"
    "libnvrtc-builtins.so"
)


if [[ "$OSTYPE" == "darwin"* ]]; then
    MACOSX_DEPLOYMENT_TARGET=10.9 python setup.py install
else
    # install
    python setup.py install

    # copy over needed dependent .so files over and tag them with their hash
    patched=()
    for filepath in "${DEPS_LIST[@]}"
    do
	filename=$(basename $filepath)
	destpath=$SP_DIR/torch/lib/$filename
	cp $filepath $destpath

	patchedpath=$(fname_with_sha256 $destpath)
	patchedname=$(basename $patchedpath)
	set +e
	mv $destpath $patchedpath
	set -e

	patched+=("$patchedname")
	echo "Copied $filepath to $patchedpath"
    done

    # run patchelf to fix the so names to the hashed names
    for ((i=0;i<${#DEPS_LIST[@]};++i));
    do
	find $SP_DIR/torch -name '*.so*' | while read sofile; do
	    origname=${DEPS_SONAME[i]}
	    patchedname=${patched[i]}
	    set +e
	    patchelf --print-needed $sofile | grep $origname 2>&1 >/dev/null
	    ERRCODE=$?
	    set -e
	    if [ "$ERRCODE" -eq "0" ]; then
		echo "patching $sofile entry $origname to $patchedname"
		patchelf --replace-needed $origname $patchedname $sofile
	    fi
	done
    done

    # set RPATH of _C.so and similar to $ORIGIN, $ORIGIN/lib and conda/lib
    find $SP_DIR/torch -name "*.so*" -maxdepth 1 -type f | while read sofile; do
	echo "Setting rpath of $sofile to " '$ORIGIN:$ORIGIN/lib:$ORIGIN/../../..'
	patchelf --set-rpath '$ORIGIN:$ORIGIN/lib:$ORIGIN/../../..' $sofile
	patchelf --print-rpath $sofile
    done
    
    # set RPATH of lib/ files to $ORIGIN and conda/lib
    find $SP_DIR/torch/lib -name "*.so*" -maxdepth 1 -type f | while read sofile; do
	echo "Setting rpath of $sofile to " '$ORIGIN:$ORIGIN/lib:$ORIGIN/../../../..'
	patchelf --set-rpath '$ORIGIN:$ORIGIN/../../../..' $sofile
	patchelf --print-rpath $sofile
    done
    
fi
