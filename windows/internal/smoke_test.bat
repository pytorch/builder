set SRC_DIR=%~dp0

pushd %SRC_DIR%\..

if not "%CUDA_VERSION%" == "cpu" call internal\driver_update.bat
if errorlevel 1 exit /b 1

set "ORIG_PATH=%PATH%"

setlocal EnableDelayedExpansion
set NVIDIA_GPU_EXISTS=0
for /F "delims=" %%i in ('wmic path win32_VideoController get name') do (
    set GPUS=%%i
    if not "x!GPUS:NVIDIA=!" == "x!GPUS!" (
        SET NVIDIA_GPU_EXISTS=1
        goto gpu_check_end
    )
)
:gpu_check_end
endlocal & set NVIDIA_GPU_EXISTS=%NVIDIA_GPU_EXISTS%

if "%PACKAGE_TYPE%" == "wheel" goto wheel
if "%PACKAGE_TYPE%" == "conda" goto conda
if "%PACKAGE_TYPE%" == "libtorch" goto libtorch

echo "unknown package type"
exit /b 1

:wheel
echo "install wheel package"

set PYTHON_INSTALLER_URL=
if "%DESIRED_PYTHON%" == "3.10" set "PYTHON_INSTALLER_URL=https://www.python.org/ftp/python/3.10.0/python-3.10.0-amd64.exe"
if "%DESIRED_PYTHON%" == "3.9" set "PYTHON_INSTALLER_URL=https://www.python.org/ftp/python/3.9.0/python-3.9.0-amd64.exe"
if "%DESIRED_PYTHON%" == "3.8" set "PYTHON_INSTALLER_URL=https://www.python.org/ftp/python/3.8.2/python-3.8.2-amd64.exe"
if "%DESIRED_PYTHON%" == "3.7" set "PYTHON_INSTALLER_URL=https://www.python.org/ftp/python/3.7.9/python-3.7.9-amd64.exe"
if "%DESIRED_PYTHON%" == "3.6" set "PYTHON_INSTALLER_URL=https://www.python.org/ftp/python/3.6.8/python-3.6.8-amd64.exe"
if "%PYTHON_INSTALLER_URL%" == "" (
    echo Python %DESIRED_PYTHON% not supported yet
)

del python-amd64.exe
curl --retry 3 -kL "%PYTHON_INSTALLER_URL%" --output python-amd64.exe
if errorlevel 1 exit /b 1

start /wait "" python-amd64.exe /quiet InstallAllUsers=1 PrependPath=1 Include_test=0 TargetDir=%CD%\Python
if errorlevel 1 exit /b 1

set "PATH=%CD%\Python%PYTHON_VERSION%\Scripts;%CD%\Python;%PATH%"

pip install -q numpy protobuf "mkl>=2019"
if errorlevel 1 exit /b 1

if "%TEST_NIGHTLY_PACKAGE%" == "1" (
    call internal\install_nightly_package.bat
    if errorlevel 1 exit /b 1
) else (
    for /F "delims=" %%i in ('where /R "%PYTORCH_FINAL_PACKAGE_DIR:/=\%" *.whl') do pip install "%%i"
    if errorlevel 1 exit /b 1
)

goto smoke_test

:conda
echo "install conda package"

:: Install Miniconda3
set "CONDA_HOME=%CD%\conda"
set "tmp_conda=%CONDA_HOME%"
set "miniconda_exe=%CD%\miniconda.exe"
set "CONDA_EXTRA_ARGS="
if "%CUDA_VERSION%" == "111" (
    set "CONDA_EXTRA_ARGS=-c=nvidia"
)
if "%CUDA_VERSION%" == "112" (
    set "CONDA_EXTRA_ARGS=-c=nvidia"
)
if "%CUDA_VERSION%" == "115" (
    set "CONDA_EXTRA_ARGS=-c=nvidia"
)


rmdir /s /q conda
del miniconda.exe
curl -k https://repo.anaconda.com/miniconda/Miniconda3-latest-Windows-x86_64.exe -o "%miniconda_exe%"
call ..\conda\install_conda.bat
if ERRORLEVEL 1 exit /b 1

set "PATH=%CONDA_HOME%;%CONDA_HOME%\scripts;%CONDA_HOME%\Library\bin;%PATH%"

conda create -qyn testenv python=%DESIRED_PYTHON%
if errorlevel 1 exit /b 1

call %CONDA_HOME%\condabin\activate.bat testenv
if errorlevel 1 exit /b 1

call conda update -n base -y -c defaults conda
if "%PACKAGE_TYPE%" == "conda" (if "%DESIRED_PYTHON%" == "3.10"  (
    call conda install -c=conda-forge -y cudatoolkit
    if errorlevel 1 exit /b 1
))

call conda install %CONDA_EXTRA_ARGS% -yq  protobuf numpy
if ERRORLEVEL 1 exit /b 1

set /a CUDA_VER=%CUDA_VERSION%
set CUDA_VER_MAJOR=%CUDA_VERSION:~0,-1%
set CUDA_VER_MINOR=%CUDA_VERSION:~-1,1%
set CUDA_VERSION_STR=%CUDA_VER_MAJOR%.%CUDA_VER_MINOR%

if "%TEST_NIGHTLY_PACKAGE%" == "1" (
    call internal\install_nightly_package.bat
    if errorlevel 1 exit /b 1
    goto smoke_test
)

for /F "delims=" %%i in ('where /R "%PYTORCH_FINAL_PACKAGE_DIR:/=\%" *.tar.bz2') do call conda install %CONDA_EXTRA_ARGS% -y "%%i" --offline
if ERRORLEVEL 1 exit /b 1

if "%CUDA_VERSION%" == "cpu" goto install_cpu_torch

:: We do an update --all here since that will install the dependencies for any package that's installed offline
call conda update --all %CONDA_EXTRA_ARGS% -y -c pytorch -c defaults -c numba/label/dev
if ERRORLEVEL 1 exit /b 1

goto smoke_test

:install_cpu_torch
call conda install %CONDA_EXTRA_ARGS% -y cpuonly -c pytorch
if ERRORLEVEL 1 exit /b 1

:smoke_test
python -c "import torch"
if ERRORLEVEL 1 exit /b 1

echo Checking that MKL is available
python -c "import torch; exit(0 if torch.backends.mkl.is_available() else 1)"
if ERRORLEVEL 1 exit /b 1

if "%NVIDIA_GPU_EXISTS%" == "0" (
    echo "Skip CUDA tests for machines without a Nvidia GPU card"
    goto end
)

echo Checking that CUDA archs are setup correctly
python -c "import torch; torch.randn([3,5]).cuda()"
if ERRORLEVEL 1 exit /b 1

echo Checking that magma is available
python -c "import torch; torch.rand(1).cuda(); exit(0 if torch.cuda.has_magma else 1)"
if ERRORLEVEL 1 exit /b 1

echo Checking that CuDNN is available
python -c "import torch; exit(0 if torch.backends.cudnn.is_available() else 1)"
if ERRORLEVEL 1 exit /b 1

echo Checking that basic RNN works
python %BUILDER_ROOT%\test_example_code\rnn_smoke.py
if ERRORLEVEL 1 exit /b 1

echo Checking that basic CNN works
python %BUILDER_ROOT%\test_example_code\cnn_smoke.py
if ERRORLEVEL 1 exit /b 1

goto end

:libtorch
echo "install and test libtorch"

if "%VC_YEAR%" == "2017" powershell internal\vs2017_install.ps1
if ERRORLEVEL 1 exit /b 1

if "%TEST_NIGHTLY_PACKAGE%" == "1" (
    call internal\install_nightly_package.bat
    if errorlevel 1 exit /b 1
) else (
    for /F "delims=" %%i in ('where /R "%PYTORCH_FINAL_PACKAGE_DIR:/=\%" *-latest.zip') do 7z x "%%i" -otmp
    if ERRORLEVEL 1 exit /b 1
)

pushd tmp\libtorch

set VC_VERSION_LOWER=16
set VC_VERSION_UPPER=17
IF "%VC_YEAR%" == "2017" (
    set VC_VERSION_LOWER=15
    set VC_VERSION_UPPER=16
)

for /f "usebackq tokens=*" %%i in (`"%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe" -legacy -products * -version [%VC_VERSION_LOWER%^,%VC_VERSION_UPPER%^) -property installationPath`) do (
    if exist "%%i" if exist "%%i\VC\Auxiliary\Build\vcvarsall.bat" (
        set "VS15INSTALLDIR=%%i"
        set "VS15VCVARSALL=%%i\VC\Auxiliary\Build\vcvarsall.bat"
        goto vswhere
    )
)

:vswhere
IF "%VS15VCVARSALL%"=="" (
    echo Visual Studio 2017 C++ BuildTools is required to compile PyTorch test on Windows
    exit /b 1
)
call "%VS15VCVARSALL%" x64

set install_root=%CD%
set INCLUDE=%INCLUDE%;%install_root%\include;%install_root%\include\torch\csrc\api\include
set LIB=%LIB%;%install_root%\lib
set PATH=%PATH%;%install_root%\lib

cl %BUILDER_ROOT%\test_example_code\simple-torch-test.cpp c10.lib torch_cpu.lib /EHsc
if ERRORLEVEL 1 exit /b 1

.\simple-torch-test.exe
if ERRORLEVEL 1 exit /b 1

cl %BUILDER_ROOT%\test_example_code\check-torch-mkl.cpp c10.lib torch_cpu.lib /EHsc
if ERRORLEVEL 1 exit /b 1

.\check-torch-mkl.exe
if ERRORLEVEL 1 exit /b 1

if "%NVIDIA_GPU_EXISTS%" == "0" (
    echo "Skip CUDA tests for machines without a Nvidia GPU card"
    goto end
)

set BUILD_SPLIT_CUDA=
if exist "%install_root%\lib\torch_cuda_cu.lib" if exist "%install_root%\lib\torch_cuda_cpp.lib" set BUILD_SPLIT_CUDA=ON

if "%BUILD_SPLIT_CUDA%" == "ON" (
    cl %BUILDER_ROOT%\test_example_code\check-torch-cuda.cpp torch_cpu.lib c10.lib torch_cuda_cu.lib torch_cuda_cpp.lib /EHsc /link /INCLUDE:?warp_size@cuda@at@@YAHXZ /INCLUDE:?_torch_cuda_cu_linker_symbol_op_cuda@native@at@@YA?AVTensor@2@AEBV32@@Z
) else (
    cl %BUILDER_ROOT%\test_example_code\check-torch-cuda.cpp torch_cpu.lib c10.lib torch_cuda.lib /EHsc /link /INCLUDE:?warp_size@cuda@at@@YAHXZ
)
.\check-torch-cuda.exe
if ERRORLEVEL 1 exit /b 1

popd

echo Cleaning temp files
rd /s /q "tmp" || ver > nul

:end
set "PATH=%ORIG_PATH%"
popd
