#!/usr/bin/env bash
set -ex

export CMAKE_LIBRARY_PATH=$PREFIX/lib:$PREFIX/include:$CMAKE_LIBRARY_PATH
export CMAKE_PREFIX_PATH=$PREFIX
export TH_BINARY_BUILD=1
export PYTORCH_BUILD_VERSION=$PKG_VERSION
export PYTORCH_BUILD_NUMBER=$PKG_BUILDNUM

if [[ -z "$NO_CUDA" || "$NO_CUDA" == 0 ]]; then
    # compile for Kepler, Kepler+Tesla, Maxwell, Volta
    export TORCH_CUDA_ARCH_LIST="3.5;5.0+PTX;6.0;6.1"
    export TORCH_NVCC_FLAGS="-Xfatbin -compress-all"
    export NCCL_ROOT_DIR=/usr/local/cuda
    export USE_STATIC_CUDNN=1
    export USE_STATIC_NCCL=1
    export ATEN_STATIC_CUDA=1
    export USE_CUDA_STATIC_LINK=1
fi

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
)

DEPS_SONAME=(
)


if [[ "$OSTYPE" == "darwin"* ]]; then
    DEVELOPER_DIR=/Applications/Xcode9.app/Contents/Developer \
        MACOSX_DEPLOYMENT_TARGET=10.9 \
        CXX=clang++ \
        CC=clang \
        python setup.py install
else
    # install
    python setup.py install

    # copy over needed dependent .so files over and tag them with their hash
    patched=()
    for filepath in "${DEPS_LIST[@]}"; do
	      filename=$(basename $filepath)
	      destpath=$SP_DIR/torch/lib/$filename
	      cp $filepath $destpath

	      patchedpath=$(fname_with_sha256 $destpath)
	      patchedname=$(basename $patchedpath)
	      mv $destpath $patchedpath

	      patched+=("$patchedname")
	      echo "Copied $filepath to $patchedpath"
    done

    # run patchelf to fix the so names to the hashed names
    for ((i=0;i<${#DEPS_LIST[@]};++i)); do
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
