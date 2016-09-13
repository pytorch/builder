export CMAKE_LIBRARY_PATH=$PREFIX/lib:$PREFIX/include:$CMAKE_LIBRARY_PATH
export CMAKE_PREFIX_PATH=$PREFIX
export PATH=$PREFIX/bin:$PATH

mkdir build
cd build
cmake .. -DUSE_FORTRAN=OFF -DGPU_TARGET="All"
make -j40
cp lib/libmagma.a $PREFIX/lib
cp lib/libmagma_sparse.a $PREFIX/lib
cd ..
