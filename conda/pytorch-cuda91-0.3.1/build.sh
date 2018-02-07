export CMAKE_LIBRARY_PATH=$PREFIX/lib:$PREFIX/include:$CMAKE_LIBRARY_PATH
export CMAKE_PREFIX_PATH=$PREFIX
# compile for Kepler, Kepler+Tesla, Maxwell, Pascal, Volta
export TORCH_CUDA_ARCH_LIST="3.5;5.2+PTX;6.0;6.1;7.0"
export TORCH_NVCC_FLAGS="-Xfatbin -compress-all"
export PYTORCH_BINARY_BUILD=1
export TH_BINARY_BUILD=1
export PYTORCH_BUILD_VERSION=$PKG_VERSION
export PYTORCH_BUILD_NUMBER=$PKG_BUILDNUM
# export NCCL_ROOT_DIR=/usr/local/cuda
rm -f /usr/local/cuda/include/nccl.h || true

# for some reason if we use exact version numbers for CUDA9 .so files 
# (like .so.9.0.176), we see segfaults during dlopen somewhere
# deep inside these libs.
# hence for CUDA9, use .9.0, and dont use hashed names
DEPS_LIST=(
    "/usr/local/cuda/lib64/libcudart.so.9.0"
    "/usr/local/cuda/lib64/libnvToolsExt.so.1"
    "/usr/local/cuda/lib64/libcublas.so.9.0"
    "/usr/local/cuda/lib64/libcurand.so.9.0"
    "/usr/local/cuda/lib64/libcusparse.so.9.0"
    "/usr/local/cuda/lib64/libnvrtc.so.9.0"
    "/usr/local/cuda/lib64/libnvrtc-builtins.so"
    "/usr/local/cuda/lib64/libcudnn.so.7"
)

DEPS_SONAME=(
    "libcudart.so.9.0"
    "libnvToolsExt.so.1"
    "libcublas.so.9.0"
    "libcurand.so.9.0"
    "libcusparse.so.9.0"
    "libnvrtc.so.9.0"
    "libnvrtc-builtins.so"
    "libcudnn.so.7"
)

if [[ "$OSTYPE" == "darwin"* ]]; then
    MACOSX_DEPLOYMENT_TARGET=10.9 python setup.py install
else
    # install
    python setup.py install

    # copy over needed dependent .so files over
    for filepath in "${DEPS_LIST[@]}"
    do
    	filename=$(basename $filepath)
    	destpath=$SP_DIR/torch/lib/$filename
    	cp $filepath $destpath

    	echo "Copied $filepath to $destpath"
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
