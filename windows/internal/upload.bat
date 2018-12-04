@echo off

IF "%CONDA_UPLOADER_INSTALLATION%" == "" goto precheck_fail
IF "%PYTORCH_FINAL_PACKAGE_DIR%" == "" goto precheck_fail
IF "%today%" == "" goto precheck_fail

goto precheck_pass

:precheck_fail

echo Please run nightly_defaults.bat first.
echo And remember to set `PYTORCH_FINAL_PACKAGE_DIR`
exit /b 1

:precheck_pass

pushd %today%

:: Install anaconda client
set "CONDA_HOME=%CONDA_UPLOADER_INSTALLATION%\conda"
set "tmp_conda=%CONDA_HOME%"
set "miniconda_exe=%CD%\miniconda.exe"
rmdir /s /q "%CONDA_HOME%"
del miniconda.exe
curl -k https://repo.continuum.io/miniconda/Miniconda3-latest-Windows-x86_64.exe -o "%miniconda_exe%"
popd

IF ERRORLEVEL 1 (
    echo Conda download failed
    exit /b 1
)

call %~dp0\..\..\conda\install_conda.bat

IF ERRORLEVEL 1 (
    echo Conda installation failed
    exit /b 1
)

set "ORIG_PATH=%PATH%"
set "PATH=%CONDA_HOME%;%CONDA_HOME%\scripts;%CONDA_HOME%\Library\bin;%PATH%"

conda install -y anaconda-client
IF ERRORLEVEL 1 (
    echo Anaconda client installation failed
    exit /b 1
)

echo yes | anaconda login --username "%PYTORCH_ANACONDA_USERNAME%" --password "%PYTORCH_ANACONDA_PASSWORD%"

:: Upload all the packages under `PYTORCH_FINAL_PACKAGE_DIR`
FOR /F "delims=" %%i IN ('where /R %PYTORCH_FINAL_PACKAGE_DIR% *pytorch*.tar.bz2') DO (
    echo Uploading %%i to Anaconda Cloud
    anaconda upload "%%i" -u pytorch --label main --force --no-progress
    IF ERRORLEVEL 1 echo Upload %%i failed
)
