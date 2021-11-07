IF "%DESIRED_PYTHON%"=="" (
    echo DESIRED_PYTHON is NOT defined.
    exit /b 1
)

:: Create a new conda environment
setlocal EnableDelayedExpansion
FOR %%v IN (%DESIRED_PYTHON%) DO (
    set PYTHON_VERSION_STR=%%v
    set PYTHON_VERSION_STR=!PYTHON_VERSION_STR:.=!
    conda remove -n py!PYTHON_VERSION_STR! --all -y || rmdir %CONDA_HOME%\envs\py!PYTHON_VERSION_STR! /s
    if "%%v" == "3.6" call conda create -n py!PYTHON_VERSION_STR! -y -q numpy=1.11 "mkl=2020.2" cffi pyyaml boto3 cmake ninja typing_extensions dataclasses python=%%v
    if "%%v" == "3.7" call conda create -n py!PYTHON_VERSION_STR! -y -q numpy=1.11 "mkl=2020.2" cffi pyyaml boto3 cmake ninja typing_extensions python=%%v
    if "%%v" == "3.8" call conda create -n py!PYTHON_VERSION_STR! -y -q numpy=1.11 "mkl=2020.2" pyyaml boto3 cmake ninja typing_extensions python=%%v
    if "%%v" == "3.9" call conda create -n py!PYTHON_VERSION_STR! -y -q "numpy>=1.11" "mkl=2020.2" pyyaml boto3 cmake ninja typing_extensions python=%%v
    if "%%v" == "3" call conda create -n py!PYTHON_VERSION_STR! -y -q numpy=1.11 "mkl=2020.2" pyyaml boto3 cmake ninja typing_extensions python=%%v
)
endlocal

:: Install libuv
conda install -y -q -c conda-forge libuv=1.39
set libuv_ROOT=%CONDA_HOME%\Library
echo libuv_ROOT=%libuv_ROOT%
