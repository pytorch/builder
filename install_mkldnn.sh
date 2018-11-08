set -ex

export CMAKE_INSTALL_PREFIX=/usr/local/mkl-dnn

# Clone the repo
git clone https://github.com/intel/mkl-dnn.git

echo 'Running prepare_mkl script'
pushd mkl-dnn/scripts && ./prepare_mkl.sh && popd

echo "Building mkl-dnn into $CMAKE_INSTALL_PREFIX"
pushd mkl-dnn && mkdir -p build && pushd build
cmake -DCMAKE_INSTALL_PREFIX="$CMAKE_INSTALL_PREFIX" ..
make install
popd
popd

# Clean up build folder
rm -rf mkl-dnn
