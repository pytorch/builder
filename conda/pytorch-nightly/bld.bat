@echo off

set PYTORCH_BINARY_BUILD=1
set TH_BINARY_BUILD=1
set PYTORCH_BUILD_VERSION=%PKG_VERSION%
set PYTORCH_BUILD_NUMBER=%PKG_BUILDNUM%

if "%NO_CUDA%" == "" (
    set build_with_cuda=1
    set desired_cuda=%CUDA_VERSION:~0,-1%.%CUDA_VERSION:~-1,1%
) else (
    set build_with_cuda=
)

if NOT "%build_with_cuda%" == "" (
    set CUDA_PATH=C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v%desired_cuda%
    set CUDA_BIN_PATH=%CUDA_PATH%\bin
    set TORCH_CUDA_ARCH_LIST=3.5;5.0+PTX;6.0;6.1
    set TORCH_NVCC_FLAGS=-Xfatbin -compress-all
)

set DISTUTILS_USE_SDK=1

curl https://s3.amazonaws.com/ossci-windows/mkl_2018.2.185.7z -k -O
7z x -aoa mkl_2018.2.185.7z -omkl
set CMAKE_INCLUDE_PATH=%SRC_DIR%\\mkl\\include
set LIB=%SRC_DIR%\\mkl\\lib;%LIB%

IF "%USE_SCCACHE%" == "1" (
    mkdir %SRC_DIR%\\tmp_bin
    curl -k https://s3.amazonaws.com/ossci-windows/sccache.exe --output %SRC_DIR%\\tmp_bin\\sccache.exe
    copy %SRC_DIR%\\tmp_bin\\sccache.exe %SRC_DIR%\\tmp_bin\\nvcc.exe
    set "PATH=%SRC_DIR%\\tmp_bin;%PATH%"
)

set "PATH=C:\Program Files\CMake\bin;%PATH%"

if NOT "%build_with_cuda%" == "" (
    curl https://s3.amazonaws.com/ossci-windows/magma_cuda%CUDA_VERSION%_release_mkl_2018.2.185.7z -k -O
    7z x -aoa magma_cuda%CUDA_VERSION%_release_mkl_2018.2.185.7z -omagma_cuda%CUDA_VERSION%_release
    if "%CUDA_VERSION%" == "92" (
        set MAGMA_HOME=%cd%\magma_cuda92_release\\magma_cuda92\\magma\\install
    ) else (
        set MAGMA_HOME=%cd%\magma_cuda%CUDA_VERSION%_release
    )

    IF "%USE_SCCACHE%" == "1" (
        set CUDA_NVCC_EXECUTABLE=%SRC_DIR%\\tmp_bin\\nvcc
    )

    set "PATH=%CUDA_BIN_PATH%;%PATH%"

    if "%CUDA_VERSION%" == "80" (
        :: Only if you use Ninja with CUDA 8
        set "CUDA_HOST_COMPILER=%VS140COMNTOOLS%\..\..\VC\bin\amd64\cl.exe"
    )
)

set CMAKE_GENERATOR=Ninja

IF "%USE_SCCACHE%" == "1" (
    sccache --stop-server
    sccache --start-server
    sccache --zero-stats

    set CC=sccache cl
    set CXX=sccache cl
)


pip install ninja

python setup.py install

pip uninstall -y ninja

IF "%USE_SCCACHE%" == "1" (
    taskkill /im sccache.exe /f /t || ver > nul
)

if NOT "%build_with_cuda%" == "" (
    copy "%CUDA_BIN_PATH%\cusparse64_%CUDA_VERSION%.dll*" %SP_DIR%\torch\lib
    copy "%CUDA_BIN_PATH%\cublas64_%CUDA_VERSION%.dll*" %SP_DIR%\torch\lib
    copy "%CUDA_BIN_PATH%\cudart64_%CUDA_VERSION%.dll*" %SP_DIR%\torch\lib
    copy "%CUDA_BIN_PATH%\curand64_%CUDA_VERSION%.dll*" %SP_DIR%\torch\lib
    copy "%CUDA_BIN_PATH%\cufft64_%CUDA_VERSION%.dll*" %SP_DIR%\torch\lib
    copy "%CUDA_BIN_PATH%\cufftw64_%CUDA_VERSION%.dll*" %SP_DIR%\torch\lib

    copy "%CUDA_BIN_PATH%\cudnn64_%CUDNN_VERSION%.dll*" %SP_DIR%\torch\lib
    copy "%CUDA_BIN_PATH%\nvrtc64_%CUDA_VERSION%.dll*" %SP_DIR%\torch\lib
    copy "%CUDA_BIN_PATH%\nvrtc-builtins64_%CUDA_VERSION%.dll*" %SP_DIR%\torch\lib

    copy "C:\Program Files\NVIDIA Corporation\NvToolsExt\bin\x64\nvToolsExt64_1.dll*" %SP_DIR%\torch\lib
    copy "C:\Windows\System32\nvcuda.dll" %SP_DIR%\torch\lib
    copy "C:\Windows\System32\nvfatbinaryloader.dll" %SP_DIR%\torch\lib
)
