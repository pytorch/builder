#!bin/bash

mkdir build
cd build
cmake .. -DCMAKE_INSTALL_PREFIX=$PREFIX -DCMAKE_POSITION_INDEPENDENT_CODE:BOOL=true
make -j$(getconf _NPROCESSORS_CONF)
make install
cd ..

# These are the files we actually care about. If we wanted to
# isolate them, we could make install into a different location
# and then copy them into $PREFIX

# cp -p include/nnpack.h $PREFIX/include
# cp -p lib/libnnpack.a $PREFIX/lib
# cp -p lib/libpthreadpool.a $PREFIX/lib
# cp -p deps/pthreadpool/include/pthreadpool.h $PREFIX/include
