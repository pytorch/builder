@echo off

IF NOT EXIST "setup.py" IF NOT EXIST "pytorch" (
    call internal\clone.bat
    cd ..
    IF ERRORLEVEL 1 goto eof
) ELSE (
    call internal\clean.bat
)

call internal\check_deps.bat
IF ERRORLEVEL 1 goto eof

REM Check for optional components

set USE_CUDA=
set CMAKE_GENERATOR=Visual Studio 15 2017 Win64

IF "%NVTOOLSEXT_PATH%"=="" (
    echo NVTX ^(Visual Studio Extension ^for CUDA^) ^not installed, disabling CUDA
    set USE_CUDA=0
    goto optcheck
)

IF "%CUDA_PATH_V9_2%"=="" (
    echo CUDA 9.2 not found, disabling it
    set USE_CUDA=0
) ELSE (
    set TORCH_CUDA_ARCH_LIST=3.5;5.0+PTX;6.0;6.1;7.0
    set TORCH_NVCC_FLAGS=-Xfatbin -compress-all

    set "CUDA_PATH=%CUDA_PATH_V9_2%"
    set "PATH=%CUDA_PATH_V9_2%\bin;%PATH%"
)

:optcheck

call internal\check_opts.bat
IF ERRORLEVEL 1 goto eof

call internal\copy.bat
IF ERRORLEVEL 1 goto eof

call internal\setup.bat
IF ERRORLEVEL 1 goto eof

:eof
