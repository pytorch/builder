@echo off

:: This script parses args, installs required libraries (miniconda, MKL,
:: Magma), and then delegates to cpu.bat, cuda80.bat, etc.

if not "%CUDA_VERSION%" == "" if not "%PYTORCH_BUILD_VERSION%" == "" if not "%PYTORCH_BUILD_NUMBER%" == "" goto env_end
if "%~1"=="" goto arg_error
if "%~2"=="" goto arg_error
if "%~3"=="" goto arg_error
if not "%~4"=="" goto arg_error
goto arg_end

:arg_error

echo Illegal number of parameters. Pass cuda version, pytorch version, build number
echo CUDA version should be Mm with no dot, e.g. '80'
echo DESIRED_PYTHON should be M.m, e.g. '2.7'
exit /b 1

:arg_end

set CUDA_VERSION=%~1
set PYTORCH_BUILD_VERSION=%~2
set PYTORCH_BUILD_NUMBER=%~3

:env_end

if not "%CUDA_VERSION%" == "cpu" (
    set CUDA_PREFIX=cuda%CUDA_VERSION%
) else (
    set CUDA_PREFIX=cpu
)

if "%DESIRED_PYTHON%" == "" set DESIRED_PYTHON=3.5;3.6;3.7
set DESIRED_PYTHON_PREFIX=%DESIRED_PYTHON:.=%
set DESIRED_PYTHON_PREFIX=py%DESIRED_PYTHON_PREFIX:;=;py%

set SRC_DIR=%~dp0
pushd %SRC_DIR%

:: Install Miniconda3
set "CONDA_HOME=%CD%\conda"
set "tmp_conda=%CONDA_HOME%"
set "miniconda_exe=%CD%\miniconda.exe"
rmdir /s /q conda
del miniconda.exe
curl -k https://repo.anaconda.com/miniconda/Miniconda3-latest-Windows-x86_64.exe -o "%miniconda_exe%"
call ..\conda\install_conda.bat
if ERRORLEVEL 1 exit /b 1
set "ORIG_PATH=%PATH%"
set "PATH=%CONDA_HOME%;%CONDA_HOME%\scripts;%CONDA_HOME%\Library\bin;%PATH%"

:: Create a new conda environment
setlocal EnableDelayedExpansion
FOR %%v IN (%DESIRED_PYTHON%) DO (
    set PYTHON_VERSION_STR=%%v
    set PYTHON_VERSION_STR=!PYTHON_VERSION_STR:.=!
    conda remove -n py!PYTHON_VERSION_STR! --all -y || rmdir %CONDA_HOME%\envs\py!PYTHON_VERSION_STR! /s
    if "%%v" == "3.6" conda create -n py!PYTHON_VERSION_STR! -y -q numpy=1.11 "mkl=2020.2" cffi pyyaml boto3 cmake ninja typing_extensions dataclasses python=%%v
    if "%%v" == "3.7" conda create -n py!PYTHON_VERSION_STR! -y -q numpy=1.11 "mkl=2020.2" cffi pyyaml boto3 cmake ninja typing_extensions python=%%v
    if "%%v" == "3.8" conda create -n py!PYTHON_VERSION_STR! -y -q numpy=1.11 "mkl=2020.2" pyyaml boto3 cmake ninja typing_extensions python=%%v
    if "%%v" == "3.9" conda create -n py!PYTHON_VERSION_STR! -y -q "numpy>=1.11" "mkl=2020.2" pyyaml boto3 cmake ninja typing_extensions python=%%v
    if "%%v" == "3" conda create -n py!PYTHON_VERSION_STR! -y -q numpy=1.11 "mkl=2020.2" pyyaml boto3 cmake ninja typing_extensions python=%%v
)
endlocal

::Install libuv
conda install -y -q -c conda-forge libuv=1.39
set libuv_ROOT=%CONDA_HOME%\Library
echo libuv_ROOT=%libuv_ROOT%

:: Install MKL
rmdir /s /q mkl
del mkl_2020.2.254.7z
curl https://s3.amazonaws.com/ossci-windows/mkl_2020.2.254.7z -k -O
7z x -aoa mkl_2020.2.254.7z -omkl
set CMAKE_INCLUDE_PATH=%cd%\mkl\include
set LIB=%cd%\mkl\lib;%LIB%

:: Download MAGMA Files on CUDA builds
set MAGMA_VERSION=2.5.4
if "%CUDA_VERSION%" == "92" set MAGMA_VERSION=2.5.2
if "%CUDA_VERSION%" == "100" set MAGMA_VERSION=2.5.2

if "%DEBUG%" == "1" (
    set BUILD_TYPE=debug
) else (
    set BUILD_TYPE=release
)

if not "%CUDA_VERSION%" == "cpu" (
    rmdir /s /q magma_%CUDA_PREFIX%_%BUILD_TYPE%
    del magma_%CUDA_PREFIX%_%BUILD_TYPE%.7z
    curl -k https://s3.amazonaws.com/ossci-windows/magma_%MAGMA_VERSION%_%CUDA_PREFIX%_%BUILD_TYPE%.7z -o magma_%CUDA_PREFIX%_%BUILD_TYPE%.7z
    7z x -aoa magma_%CUDA_PREFIX%_%BUILD_TYPE%.7z -omagma_%CUDA_PREFIX%_%BUILD_TYPE%
)

:: Install sccache
if "%USE_SCCACHE%" == "1" (
    mkdir %CD%\tmp_bin
    curl -k https://s3.amazonaws.com/ossci-windows/sccache.exe --output %CD%\tmp_bin\sccache.exe
    curl -k https://s3.amazonaws.com/ossci-windows/sccache-cl.exe --output %CD%\tmp_bin\sccache-cl.exe
    if not "%CUDA_VERSION%" == "" (
        copy %CD%\tmp_bin\sccache.exe %CD%\tmp_bin\nvcc.exe

        set CUDA_NVCC_EXECUTABLE=%CD%\tmp_bin\nvcc
        set ADDITIONAL_PATH=%CD%\tmp_bin
        set SCCACHE_IDLE_TIMEOUT=1500

        :: randomtemp is used to resolve the intermittent build error related to CUDA.
        :: code: https://github.com/peterjc123/randomtemp-rust
        :: issue: https://github.com/pytorch/pytorch/issues/25393
        ::
        :: Previously, CMake uses CUDA_NVCC_EXECUTABLE for finding nvcc and then
        :: the calls are redirected to sccache. sccache looks for the actual nvcc
        :: in PATH, and then pass the arguments to it.
        :: Currently, randomtemp is placed before sccache (%TMP_DIR_WIN%\bin\nvcc)
        :: so we are actually pretending sccache instead of nvcc itself.
        curl -kL https://github.com/peterjc123/randomtemp-rust/releases/download/v0.3/randomtemp.exe --output %CD%\tmp_bin\randomtemp.exe
        set RANDOMTEMP_EXECUTABLE=%CD%\tmp_bin\nvcc.exe
        set CUDA_NVCC_EXECUTABLE=%CD%\tmp_bin\randomtemp.exe
        set RANDOMTEMP_BASEDIR=%CD%\tmp_bin
    )
)

set PYTORCH_BINARY_BUILD=1
set TH_BINARY_BUILD=1
set INSTALL_TEST=0

for %%v in (%DESIRED_PYTHON_PREFIX%) do (
    :: Activate Python Environment
    set PYTHON_PREFIX=%%v
    set "CONDA_LIB_PATH=%CONDA_HOME%\envs\%%v\Library\bin"
    if not "%ADDITIONAL_PATH%" == "" (
        set "PATH=%ADDITIONAL_PATH%;%CONDA_HOME%\envs\%%v;%CONDA_HOME%\envs\%%v\scripts;%CONDA_HOME%\envs\%%v\Library\bin;%ORIG_PATH%"
    ) else (
        set "PATH=%CONDA_HOME%\envs\%%v;%CONDA_HOME%\envs\%%v\scripts;%CONDA_HOME%\envs\%%v\Library\bin;%ORIG_PATH%"
    )
    pip install ninja
    @setlocal
    :: Set Flags
    if not "%CUDA_VERSION%"=="cpu" (
        set MAGMA_HOME=%cd%\magma_%CUDA_PREFIX%_%BUILD_TYPE%
    )
    call %CUDA_PREFIX%.bat
    if ERRORLEVEL 1 exit /b 1
    @endlocal
)

set "PATH=%ORIG_PATH%"
popd

if ERRORLEVEL 1 exit /b 1
