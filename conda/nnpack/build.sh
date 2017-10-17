#!bin/bash

# Instead of Conda packaging these dependencies, we expect them to be installed
# pip install --upgrade git+https://github.com/Maratyszcza/PeachPy
# pip install --upgrade git+https://github.com/Maratyszcza/confu
# conda install -c conda-forge ninja

confu setup
$PYTHON ./configure.py

# patch ninja file to compile with -fPIC support
sed -ibuild.ninja.bak "s/cflags = /cflags = -fPIC /" build.ninja
sed -ibuild.ninja.bak "s/cxxflags = /cxxflags = -fPIC /" build.ninja

ninja

# move files to expected location
mkdir -p $PREFIX/include
mkdir -p $PREFIX/lib

cp -p include/nnpack.h $PREFIX/include
cp -p lib/libnnpack.a $PREFIX/lib
cp -p lib/libpthreadpool.a $PREFIX/lib
cp -p deps/pthreadpool/include/pthreadpool.h $PREFIX/include
