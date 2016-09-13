export CMAKE_LIBRARY_PATH=$PREFIX/lib:$PREFIX/include:$CMAKE_LIBRARY_PATH
export CMAKE_PREFIX_PATH=$PREFIX
export TORCH_CUDA_ARCH_LIST="All"
export PYTORCH_BINARY_BUILD=1

export PATH=$PREFIX/bin:$PATH

if [[ "$OSTYPE" == "darwin"* ]]; then
    MACOSX_DEPLOYMENT_TARGET=10.9 python setup.py install
else
    python setup.py install

    cp -P $PREFIX/lib/libgomp.so* $SP_DIR/torch/lib
    cp -P /usr/local/cuda/lib64/libcusparse.so* $SP_DIR/torch/lib
    cp -P /usr/local/cuda/lib64/libcublas.so* $SP_DIR/torch/lib
    cp -P /usr/local/cuda/lib64/libcudart.so* $SP_DIR/torch/lib
    cp -P /usr/local/cuda/lib64/libcurand.so* $SP_DIR/torch/lib

fi
