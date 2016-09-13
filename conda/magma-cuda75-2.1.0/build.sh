export CMAKE_LIBRARY_PATH=$PREFIX/lib:$PREFIX/include:$CMAKE_LIBRARY_PATH
export CMAKE_PREFIX_PATH=$PREFIX
export PATH=$PREFIX/bin:$PATH

export GCCROOT="$HOME/bin"
export GCCVER="4.9.3"
export CC=$GCCROOT/gcc
export CXX=$GCCROOT/g++

mkdir build
cd build
cmake .. -DUSE_FORTRAN=OFF -DGPU_TARGET="All" -DCMAKE_INSTALL_PREFIX=$PREFIX
make -j40
make install
cd ..
