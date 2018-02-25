@echo off

set PATH=C:\Program Files\CMake\bin;%PATH%
set PYTORCH_BINARY_BUILD=1
set TH_BINARY_BUILD=1

set NO_CUDA=1

set DISTUTILS_USE_SDK=1

curl https://s3.amazonaws.com/ossci-windows/mkl.7z -k -O
7z x -aoa mkl.7z -omkl
set LIB=%cd%\\mkl;%LIB%

set CMAKE_GENERATOR=Ninja
set CC=cl.exe
set CXX=cl.exe

xcopy /Y %SRC_DIR%\aten\src\ATen\common_with_cwrap.py %SRC_DIR%\tools\shared\cwrap_common.py

python setup.py install
