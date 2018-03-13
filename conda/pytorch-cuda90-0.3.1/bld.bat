@echo off

set CUDA_PATH_V9_0=C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v9.0
set CUDA_PATH=%CUDA_PATH_V9_0%

set CUDA_BIN_PATH=%CUDA_PATH%\bin
set PATH=%CUDA_BIN_PATH%;C:\Program Files\CMake\bin;%PATH%
set TORCH_CUDA_ARCH_LIST=3.5;5.2+PTX;6.0;6.1;7.0
set TORCH_NVCC_FLAGS=-Xfatbin -compress-all
set PYTORCH_BINARY_BUILD=1
set TH_BINARY_BUILD=1
set PYTORCH_BUILD_VERSION=%PKG_VERSION%
set PYTORCH_BUILD_NUMBER=%PKG_BUILDNUM%

set DISTUTILS_USE_SDK=1

curl https://s3.amazonaws.com/ossci-windows/mkl.7z -k -O
7z x -aoa mkl.7z -omkl
set LIB=%cd%\mkl;%LIB%

curl https://s3.amazonaws.com/ossci-windows/magma_cuda90_release.7z -k -O
7z x -aoa magma_cuda90_release.7z -omagma_cuda90_release
set MAGMA_HOME=%cd%\magma_cuda90_release

set CMAKE_GENERATOR=Ninja
set CC=cl.exe
set CXX=cl.exe

xcopy /Y %SRC_DIR%\aten\src\ATen\common_with_cwrap.py %SRC_DIR%\tools\shared\cwrap_common.py

python setup.py install

copy "%CUDA_BIN_PATH%\cusparse64_%CUDA_VERSION%.dll*" %SP_DIR%\torch\lib
copy "%CUDA_BIN_PATH%\cublas64_%CUDA_VERSION%.dll*" %SP_DIR%\torch\lib
copy "%CUDA_BIN_PATH%\cudart64_%CUDA_VERSION%.dll*" %SP_DIR%\torch\lib
copy "%CUDA_BIN_PATH%\curand64_%CUDA_VERSION%.dll*" %SP_DIR%\torch\lib

copy "%CUDA_BIN_PATH%\cudnn64_%CUDNN_VERSION%.dll*" %SP_DIR%\torch\lib
copy "%CUDA_BIN_PATH%\nvrtc64_%CUDA_VERSION%.dll*" %SP_DIR%\torch\lib
copy "%CUDA_BIN_PATH%\nvrtc-builtins64_%CUDA_VERSION%.dll*" %SP_DIR%\torch\lib

copy "C:\Program Files\NVIDIA Corporation\NvToolsExt\bin\x64\nvToolsExt64_1.dll*" %SP_DIR%\torch\lib
