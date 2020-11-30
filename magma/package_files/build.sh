export CMAKE_LIBRARY_PATH=$PREFIX/lib:$PREFIX/include:$CMAKE_LIBRARY_PATH
export CMAKE_PREFIX_PATH=$PREFIX
export PATH=$PREFIX/bin:$PATH

CUDA__VERSION=$(nvcc --version|sed -n 4p|cut -f5 -d" "|cut -f1 -d",")
if [ "$CUDA__VERSION" != "$DESIRED_CUDA" ]; then
    echo "CUDA Version is not $DESIRED_CUDA. CUDA Version found: $CUDA__VERSION"
    exit 1
fi

mkdir build
cd build
cmake .. -DUSE_FORTRAN=OFF -DGPU_TARGET="All" -DCMAKE_INSTALL_PREFIX=$PREFIX -DCUDA_ARCH_LIST="$CUDA_ARCH_LIST"
make -j$(getconf _NPROCESSORS_CONF)
make install
cd ..
