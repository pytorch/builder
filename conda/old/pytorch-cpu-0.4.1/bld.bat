@echo off

set PYTORCH_BINARY_BUILD=1
set TH_BINARY_BUILD=1

set USE_CUDA=0

set DISTUTILS_USE_SDK=1

curl https://s3.amazonaws.com/ossci-windows/mkl_2018.2.185.7z -k -O
7z x -aoa mkl_2018.2.185.7z -omkl
set CMAKE_INCLUDE_PATH=%SRC_DIR%\\mkl\\include
set LIB=%SRC_DIR%\\mkl\\lib;%LIB%

mkdir %SRC_DIR%\\tmp_bin
curl -k https://s3.amazonaws.com/ossci-windows/sccache.exe --output %SRC_DIR%\\tmp_bin\\sccache.exe

set "PATH=%SRC_DIR%\\tmp_bin;C:\Program Files\CMake\bin;%PATH%"

set CMAKE_GENERATOR=Ninja

sccache --stop-server
sccache --start-server
sccache --zero-stats

set CC=sccache cl
set CXX=sccache cl

pip install ninja

python setup.py install

pip uninstall -y ninja

taskkill /im sccache.exe /f /t || ver > nul
