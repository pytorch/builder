export CMAKE_LIBRARY_PATH=$PREFIX/lib:$PREFIX/include:$CMAKE_LIBRARY_PATH
export CMAKE_PREFIX_PATH=$PREFIX
export PATH=$PREFIX/bin:$PATH

CUDA__VERSION=$(nvcc --version|tail -n1|cut -f5 -d" "|cut -f1 -d",")
if [ "$CUDA__VERSION" != "9.0" ]; then
    echo "CUDA Version is not 9.0. CUDA Version found: $CUDA__VERSION"
    exit 1
fi

mkdir build
cd build
cmake .. -DUSE_FORTRAN=OFF -DGPU_TARGET="All" -DCMAKE_INSTALL_PREFIX=$PREFIX
make -j$(getconf _NPROCESSORS_CONF)
make install
cd ..
