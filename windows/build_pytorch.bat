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
curl -k https://repo.continuum.io/miniconda/Miniconda3-latest-Windows-x86_64.exe -o "%miniconda_exe%"
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
    if "%%v" == "3.5" conda create -n py!PYTHON_VERSION_STR! -y -q numpy=1.11 "mkl>=2019" cffi pyyaml boto3 cmake ninja typing python=%%v
    if "%%v" == "3.6" conda create -n py!PYTHON_VERSION_STR! -y -q numpy=1.11 "mkl>=2019" cffi pyyaml boto3 cmake ninja typing python=%%v
    if "%%v" == "3.7" conda create -n py!PYTHON_VERSION_STR! -y -q numpy=1.11 "mkl>=2019" cffi pyyaml boto3 cmake ninja typing python=%%v
    if "%%v" == "3.8" conda create -n py!PYTHON_VERSION_STR! -y -q numpy=1.11 "mkl>=2019" pyyaml boto3 cmake ninja python=%%v
)
endlocal

:: Install MKL
rmdir /s /q mkl
del mkl_2019.4.245.7z
curl https://s3.amazonaws.com/ossci-windows/mkl_2019.4.245.7z -k -O
7z x -aoa mkl_2019.4.245.7z -omkl
set CMAKE_INCLUDE_PATH=%cd%\mkl\include
set LIB=%cd%\mkl\lib;%LIB%

:: Download MAGMA Files on CUDA builds
set MAGMA_VERSION=2.5.1
if "%CUDA_VERSION%" == "80" set MAGMA_VERSION=2.4.0
if "%CUDA_VERSION%" == "90" set MAGMA_VERSION=2.5.0

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
    if not "%CUDA_VERSION%" == "" (
        copy %CD%\tmp_bin\sccache.exe %CD%\tmp_bin\nvcc.exe

        set CUDA_NVCC_EXECUTABLE=%CD%\tmp_bin\nvcc
        set ADDITIONAL_PATH=%CD%\tmp_bin
        set SCCACHE_IDLE_TIMEOUT=1500
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
        set CUDNN_VERSION=7
    )
    call %CUDA_PREFIX%.bat
    if ERRORLEVEL 1 exit /b 1
    if "%BUILD_PYTHONLESS%" == "" call internal\test.bat
    if ERRORLEVEL 1 exit /b 1
    @endlocal
)

set "PATH=%ORIG_PATH%"
popd

if ERRORLEVEL 1 exit /b 1
