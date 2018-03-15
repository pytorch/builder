@echo off

set "PATH=c:\miniconda2;c:\miniconda2\scripts;%PATH%"
set "ORIG_PATH=%PATH%"

conda remove -n py35 --all -y || rmdir c:\miniconda2\envs\py35 /s
conda remove -n py36 --all -y || rmdir c:\miniconda2\envs\py36 /s

conda create -n py35 -y -q numpy mkl cffi pyyaml boto3 cmake ninja typing python=3.5
conda create -n py36 -y -q numpy mkl cffi pyyaml boto3 cmake ninja typing python=3.6

REM Install MKL
rmdir /s /q mkl
del mkl.7z
curl -k https://s3.amazonaws.com/ossci-windows/mkl.7z -o mkl.7z 
7z x -aoa mkl.7z -omkl
set LIB=%cd%\\mkl;%LIB%

REM Download MAGMA Files
for %%p in (
        cuda80
        cuda90
        cuda91
       ) do (
            rmdir /s /q magma_%%p_release
            del magma_%%p_release.7z
            curl -k https://s3.amazonaws.com/ossci-windows/magma_%%p_release.7z -o magma_%%p_release.7z
            7z x -aoa magma_%%p_release.7z -omagma_%%p_release
       )

@setlocal EnableDelayedExpansion
for %%v in (
        py35
        py36
       ) do (
            REM Activate Python Environment
            set "PATH=c:\miniconda2\envs\%%v;c:\miniconda2\envs\%%v\scripts;C:\Miniconda2\envs\%%v\Library\bin;%ORIG_PATH%"
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
