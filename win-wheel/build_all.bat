@echo off

set "CONDA_HOME=c:\ProgramData\miniconda3"
set "PATH=%CONDA_HOME%;%CONDA_HOME%\scripts;%CONDA_HOME%\Library\bin;%PATH%"
set "ORIG_PATH=%PATH%"

conda remove -n py35 --all -y || rmdir %CONDA_HOME%\envs\py35 /s
conda remove -n py36 --all -y || rmdir %CONDA_HOME%\envs\py36 /s

conda create -n py35 -y -q numpy mkl cffi pyyaml boto3 cmake ninja typing python=3.5
conda create -n py36 -y -q numpy mkl cffi pyyaml boto3 cmake ninja typing python=3.6

REM Install MKL
rmdir /s /q mkl
del mkl_2018.2.185.7z
curl https://s3.amazonaws.com/ossci-windows/mkl_2018.2.185.7z -k -O
7z x -aoa mkl_2018.2.185.7z -omkl
set CMAKE_INCLUDE_PATH=%cd%\\mkl\\include
set LIB=%cd%\\mkl\\lib;%LIB%

REM REM Download MAGMA Files
for %%p in (
        cuda80
        cuda90
        cuda91
       ) do (
            rmdir /s /q magma_%%p_release
            del magma_%%p_release.7z
            curl -k https://s3.amazonaws.com/ossci-windows/magma_%%p_release_mkl_2018.2.185.7z -o magma_%%p_release.7z
            7z x -aoa magma_%%p_release.7z -omagma_%%p_release
       )

set PYTORCH_BUILD_VERSION=0.4.0
set PYTORCH_BUILD_NUMBER=1

set PYTORCH_BINARY_BUILD=1
set TH_BINARY_BUILD=1

@setlocal EnableDelayedExpansion
for %%v in (
        py35
        py36
       ) do (
            REM Activate Python Environment
            set "PATH=%CONDA_HOME%\envs\%%v;%CONDA_HOME%\envs\%%v\scripts;%CONDA_HOME%\envs\%%v\Library\bin;%ORIG_PATH%"
            pip install ninja
            for %%c in (
                cpu
                80
                90
                91
            ) do (
                @setlocal

                REM Set Flags
                if NOT "%%c"=="cpu" (
                    set CUDA_VERSION=%%c
                    set CUDA_PREFIX=cuda!CUDA_VERSION!
                    set CUDNN_VERSION=7
                    set MAGMA_HOME=%cd%\\magma_!CUDA_PREFIX!_release
                ) else (
                    set CUDA_PREFIX=cpu
                )
                call !CUDA_PREFIX!.bat
                @endlocal
            )
       )

@endlocal

set "PATH=%ORIG_PATH%"
