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

set NO_CUDA=
set CMAKE_GENERATOR=Visual Studio 15 2017 Win64

IF "%NVTOOLSEXT_PATH%"=="" (
    echo NVTX ^(Visual Studio Extension ^for CUDA^) ^not installed, disabling CUDA
    set NO_CUDA=1
    goto optcheck
)

IF "%CUDA_PATH_V10_0%"=="" (
    echo CUDA 10.0 not found, disabling it
    set NO_CUDA=1
) ELSE (
    set TORCH_CUDA_ARCH_LIST=3.5;5.0+PTX;6.0;6.1;7.0;7.5
    set TORCH_NVCC_FLAGS=-Xfatbin -compress-all

    set "CUDA_PATH=%CUDA_PATH_V10_0%"
    set "PATH=%CUDA_PATH_V10_0%\bin;%PATH%"
)

:optcheck

call internal\check_opts.bat
IF ERRORLEVEL 1 goto eof

call internal\copy.bat
IF ERRORLEVEL 1 goto eof

call internal\setup.bat
IF ERRORLEVEL 1 goto eof

:eof
