@echo off

echo The flags after configuring:
echo NO_CUDA=%NO_CUDA%
echo CMAKE_GENERATOR=%CMAKE_GENERATOR%
if "%NO_CUDA%"==""  echo CUDA_PATH=%CUDA_PATH%
if NOT "%CC%"==""   echo CC=%CC%
if NOT "%CXX%"==""  echo CXX=%CXX%
if NOT "%DISTUTILS_USE_SDK%"==""  echo DISTUTILS_USE_SDK=%DISTUTILS_USE_SDK%

set SRC_DIR=%~dp0\..

call "%VS15VCVARSALL%" x64
call "%VS15VCVARSALL%" x86_amd64

pushd %SRC_DIR%

IF NOT exist "setup.py" (
    cd pytorch
)

if "%CXX%"=="sccache cl" (
    sccache --stop-server
    sccache --start-server
    sccache --zero-stats
)

pip wheel -e . --wheel-dir ../output/%CUDA_PREFIX%

IF ERRORLEVEL 1 exit /b 1
IF NOT ERRORLEVEL 0 exit /b 1

if "%CXX%"=="sccache cl" (
    taskkill /im sccache.exe /f /t || ver > nul
    taskkill /im nvcc.exe /f /t || ver > nul
)

cd ..
