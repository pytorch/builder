@echo off

echo The flags after configuring:
echo NO_CUDA=%NO_CUDA%
echo CMAKE_GENERATOR=%CMAKE_GENERATOR%
if "%NO_CUDA%"==""  echo CUDA_PATH=%CUDA_PATH%
if NOT "%CC%"==""   echo CC=%CC%
if NOT "%CXX%"==""  echo CXX=%CXX%
if NOT "%DISTUTILS_USE_SDK%"==""  echo DISTUTILS_USE_SDK=%DISTUTILS_USE_SDK%

set SRC_DIR=%~dp0\..

IF "%VSDEVCMD_ARGS%" == "" (
    call "%VS15VCVARSALL%" x64
    call "%VS15VCVARSALL%" x86_amd64
) ELSE (
    call "%VS15VCVARSALL%" x64 %VSDEVCMD_ARGS%
    call "%VS15VCVARSALL%" x86_amd64 %VSDEVCMD_ARGS%
)

pushd %SRC_DIR%

IF NOT exist "setup.py" (
    cd pytorch
)

if "%CXX%"=="sccache cl" (
    sccache --stop-server
    sccache --start-server
    sccache --zero-stats
)


if "%BUILD_PYTHONLESS%" == "" goto pytorch else goto libtorch

:libtorch
set VARIANT=shared-with-deps

mkdir libtorch
set "INSTALL_DIR=%CD%\libtorch"
mkdir libtorch\lib
copy /Y torch\lib\*.dll libtorch\lib\

mkdir build
pushd build
python ../tools/build_libtorch.py
popd

IF ERRORLEVEL 1 exit /b 1
IF NOT ERRORLEVEL 0 exit /b 1

move /Y libtorch\bin\*.dll libtorch\lib\

7z a -tzip libtorch-win-%VARIANT%-%PYTORCH_BUILD_VERSION%.zip libtorch\*

mkdir ..\output\%CUDA_PREFIX%
copy /Y libtorch-win-%VARIANT%-%PYTORCH_BUILD_VERSION%.zip ..\output\%CUDA_PREFIX%\
copy /Y libtorch-win-%VARIANT%-%PYTORCH_BUILD_VERSION%.zip ..\output\%CUDA_PREFIX%\libtorch-win-%VARIANT%-latest.zip

goto build_end

:pytorch
:: This stores in e.g. D:/_work/1/s/windows/output/cpu
pip wheel -e . --wheel-dir ../output/%CUDA_PREFIX%

:build_end
IF ERRORLEVEL 1 exit /b 1
IF NOT ERRORLEVEL 0 exit /b 1

if "%CXX%"=="sccache cl" (
    taskkill /im sccache.exe /f /t || ver > nul
    taskkill /im nvcc.exe /f /t || ver > nul
)

cd ..
