@echo off

set TH_BINARY_BUILD=1
set PYTORCH_BUILD_VERSION=%PKG_VERSION%
set PYTORCH_BUILD_NUMBER=%PKG_BUILDNUM%

if "%NO_CUDA%" == "" (
    set build_with_cuda=1
    set desired_cuda=%CUDA_VERSION:~0,-1%.%CUDA_VERSION:~-1,1%
) else (
    set build_with_cuda=
    set USE_CUDA=0
)

if "%build_with_cuda%" == "" goto cuda_flags_end

set CUDA_PATH=C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v%desired_cuda%
set CUDA_BIN_PATH=%CUDA_PATH%\bin
set TORCH_CUDA_ARCH_LIST=3.5;5.0+PTX
if "%desired_cuda%" == "8.0" set TORCH_CUDA_ARCH_LIST=%TORCH_CUDA_ARCH_LIST%;6.0;6.1
if "%desired_cuda%" == "9.0" set TORCH_CUDA_ARCH_LIST=%TORCH_CUDA_ARCH_LIST%;6.0;7.0
if "%desired_cuda%" == "9.2" set TORCH_CUDA_ARCH_LIST=%TORCH_CUDA_ARCH_LIST%;6.0;6.1;7.0
if "%desired_cuda%" == "10.0" set TORCH_CUDA_ARCH_LIST=%TORCH_CUDA_ARCH_LIST%;6.0;6.1;7.0;7.5
set TORCH_NVCC_FLAGS=-Xfatbin -compress-all

:cuda_flags_end

set DISTUTILS_USE_SDK=1

curl https://s3.amazonaws.com/ossci-windows/mkl_2018.2.185.7z -k -O
7z x -aoa mkl_2018.2.185.7z -omkl
set CMAKE_INCLUDE_PATH=%SRC_DIR%\mkl\include
set LIB=%SRC_DIR%\mkl\lib;%LIB%

IF "%USE_SCCACHE%" == "1" (
    mkdir %SRC_DIR%\tmp_bin
    curl -k https://s3.amazonaws.com/ossci-windows/sccache.exe --output %SRC_DIR%\tmp_bin\sccache.exe
    copy %SRC_DIR%\tmp_bin\sccache.exe %SRC_DIR%\tmp_bin\nvcc.exe
    set "PATH=%SRC_DIR%\tmp_bin;%PATH%"
)

IF "%build_with_cuda%" == "" goto cuda_end

IF "%desired_cuda%" == "8.0" (
    set MAGMA_VERSION=2.4.0
) ELSE (
    set MAGMA_VERSION=2.5.0
)

curl https://s3.amazonaws.com/ossci-windows/magma_%MAGMA_VERSION%_cuda%CUDA_VERSION%_release.7z -k -O
7z x -aoa magma_%MAGMA_VERSION%_cuda%CUDA_VERSION%_release.7z -omagma_cuda%CUDA_VERSION%_release
set MAGMA_HOME=%cd%\magma_cuda%CUDA_VERSION%_release

IF "%USE_SCCACHE%" == "1" (
    set CUDA_NVCC_EXECUTABLE=%SRC_DIR%\tmp_bin\nvcc
)

set "PATH=%CUDA_BIN_PATH%;%PATH%"

if "%CUDA_VERSION%" == "80" (
    :: Only if you use Ninja with CUDA 8
    set "CUDAHOSTCXX=%VS140COMNTOOLS%\..\..\VC\bin\amd64\cl.exe"
)

:cuda_end

set CMAKE_GENERATOR=Ninja

IF NOT "%USE_SCCACHE%" == "1" goto sccache_end

sccache --stop-server
sccache --start-server
sccache --zero-stats

set CC=sccache cl
set CXX=sccache cl

:sccache_end

python setup.py install
if errorlevel 1 exit /b 1

IF "%USE_SCCACHE%" == "1" (
    taskkill /im sccache.exe /f /t || ver > nul
    taskkill /im nvcc.exe /f /t || ver > nul
)

if NOT "%build_with_cuda%" == "" (
    copy "%CUDA_BIN_PATH%\cudnn64_%CUDNN_VERSION%.dll*" %SP_DIR%\torch\lib
)
