export CMAKE_LIBRARY_PATH=$PREFIX/lib:$PREFIX/include:$CMAKE_LIBRARY_PATH 
export CMAKE_PREFIX_PATH=$PREFIX
export TORCH_CUDA_ARCH_LIST="All"
export PYTORCH_BINARY_BUILD=1
export TH_BINARY_BUILD=1

gccf() {
       export PATH="$HOME/bin:$PATH";
       export LD_LIBRARY_PATH="$HOME/bin/gcc-4.9.3/lib64:$HOME/lib:$LD_LIBRARY_PATH";
       export CMAKE_PREFIX_PATH="$HOME/bin:$HOME/lib:$HOME/include:$CMAKE_PREFIX_PATH";
       export CC="$HOME/bin/gcc";
       export CXX="$HOME/bin/g++"
}

if [[ "$OSTYPE" == "darwin"* ]]; then
    MACOSX_DEPLOYMENT_TARGET=10.9 python setup.py install
else
    gccf
    python setup.py install
    cp -P /usr/local/cuda/lib64/libcusparse.so* $SP_DIR/torch/lib
    cp -P /usr/local/cuda/lib64/libcublas.so* $SP_DIR/torch/lib
    cp -P /usr/local/cuda/lib64/libcudart.so* $SP_DIR/torch/lib
    cp -P /usr/local/cuda/lib64/libcurand.so* $SP_DIR/torch/lib
    cp -P /home/soumith/bin/gcc-4.9.3/lib64/libgomp.so* $SP_DIR/torch/lib
    cp -P /home/soumith/Downloads/cuda/lib64/libcudnn.so.5.1.3 $SP_DIR/torch/lib
fi
