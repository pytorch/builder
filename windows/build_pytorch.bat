@echo off

if "%~1"=="" goto arg_error
if "%~2"=="" goto arg_error
if "%~3"=="" goto arg_error
if NOT "%~4"=="" goto arg_error
goto arg_end

:arg_error

echo Illegal number of parameters. Pass cuda version, pytorch version, build number
echo CUDA version should be Mm with no dot, e.g. '80'
exit /b 1

:arg_end

set CUDA_VERSION=%~1
set PYTORCH_BUILD_VERSION=%~2
set PYTORCH_BUILD_NUMBER=%~3

if NOT "%CUDA_VERSION%" == "cpu" (
    set CUDA_PREFIX=cuda%CUDA_VERSION%
else (
    set CUDA_PREFIX=cpu
)

REM Install Miniconda3
set "CONDA_HOME=%CD%\conda"
set "tmp_conda=%CONDA_HOME%"
set "miniconda_exe=%CD%\miniconda.exe"
rmdir /s /q conda
del miniconda.exe
curl -k https://repo.continuum.io/miniconda/Miniconda3-latest-Windows-x86_64.exe -o "%miniconda_exe%"
call ..\conda\install_conda.bat
set "ORIG_PATH=%PATH%"
set "PATH=%CONDA_HOME%;%CONDA_HOME%\scripts;%CONDA_HOME%\Library\bin;%PATH%"

conda remove -n py35 --all -y || rmdir %CONDA_HOME%\envs\py35 /s
conda remove -n py36 --all -y || rmdir %CONDA_HOME%\envs\py36 /s
conda remove -n py37 --all -y || rmdir %CONDA_HOME%\envs\py37 /s

conda create -n py35 -y -q numpy=1.11 mkl=2018 cffi pyyaml boto3 cmake ninja typing python=3.5
conda create -n py36 -y -q numpy=1.11 mkl=2018 cffi pyyaml boto3 cmake ninja typing python=3.6
conda create -n py37 -y -q numpy=1.11 mkl=2018 cffi pyyaml boto3 cmake ninja typing python=3.7

REM Install MKL
rmdir /s /q mkl
del mkl_2018.2.185.7z
curl https://s3.amazonaws.com/ossci-windows/mkl_2018.2.185.7z -k -O
7z x -aoa mkl_2018.2.185.7z -omkl
set CMAKE_INCLUDE_PATH=%cd%\\mkl\\include
set LIB=%cd%\\mkl\\lib;%LIB%

if NOT "%CUDA_VERSION%" == "cpu" (
    REM Download MAGMA Files
    rmdir /s /q magma_%CUDA_PREFIX%_release
    del magma_%CUDA_PREFIX%_release.7z
    curl -k https://s3.amazonaws.com/ossci-windows/magma_%CUDA_PREFIX%_release_mkl_2018.2.185.7z -o magma_%CUDA_PREFIX%_release.7z
    7z x -aoa magma_%CUDA_PREFIX%_release.7z -omagma_%CUDA_PREFIX%_release
)

REM Install sccache
mkdir %CD%\\tmp_bin
curl -k https://s3.amazonaws.com/ossci-windows/sccache.exe --output %CD%\\tmp_bin\\sccache.exe
if NOT "%CUDA_VERSION%" == "" (
    copy %CD%\\tmp_bin\\sccache.exe %CD%\\tmp_bin\\nvcc.exe

    set CUDA_NVCC_EXECUTABLE=%CD%\\tmp_bin\\nvcc
    set "PATH=%CD%\\tmp_bin;%PATH%"
)

set PYTORCH_BINARY_BUILD=1
set TH_BINARY_BUILD=1

for %%v in (
        py35
        py36
        py37
       ) do (
            REM Activate Python Environment
            set "CONDA_LIB_PATH=%CONDA_HOME%\envs\%%v\Library\bin"
            set "PATH=%CONDA_HOME%\envs\%%v;%CONDA_HOME%\envs\%%v\scripts;%CONDA_HOME%\envs\%%v\Library\bin;%ORIG_PATH%"
            pip install ninja
            @setlocal
            REM Set Flags
            if NOT "%CUDA_VERSION%"=="cpu" (
                if NOT "%CUDA_VERSION%"=="92" (
                    set MAGMA_HOME=%cd%\\magma_%CUDA_PREFIX%_release
                ) else (
                    set MAGMA_HOME=%cd%\\magma_%CUDA_PREFIX%_release\magma_cuda92\magma\install
                )
                set CUDNN_VERSION=7
            )
            call %CUDA_PREFIX%.bat
            @endlocal
       )

set "PATH=%ORIG_PATH%"
