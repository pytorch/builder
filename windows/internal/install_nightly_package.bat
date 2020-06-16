if "%PACKAGE_TYPE%" == "wheel" goto wheel
if "%PACKAGE_TYPE%" == "conda" goto conda
if "%PACKAGE_TYPE%" == "libtorch" goto libtorch

:wheel
echo "install pytorch wheel from nightly"

set pip_url="https://download.pytorch.org/whl/nightly/%DESIRED_CUDA%/torch_nightly.html"
if "%DESIRED_CUDA%" == "cu102" (
    set package_name_and_version="torch==%NIGHTLIES_DATE_PREAMBLE%%DATE%"
) else (
    set package_name_and_version="torch==%NIGHTLIES_DATE_PREAMBLE%%DATE%+%DESIRED_CUDA%"
)
pip install "%package_name_and_version%" -f "%pip_url%" --no-cache-dir --no-index -q
if errorlevel 1 exit /b 1

exit /b 0

:conda
echo "install pytorch conda from nightly"
set package_name_and_version="pytorch==%NIGHTLIES_DATE_PREAMBLE%%DATE%"

if "%DESIRED_CUDA%" == "cpu" (
    call conda install -yq -c pytorch-nightly %package_name_and_version% cpuonly
) else (
    call conda install -yq -c pytorch-nightly "cudatoolkit=%CUDA_VERSION_STR%" %package_name_and_version%
)
if ERRORLEVEL 1 exit /b 1

FOR /f %%i in ('python -c "import sys;print(sys.version)"') do set cur_python=%%i

if not %cur_python:~0,3% == %DESIRED_PYTHON% (
    echo "The Python version has changed to %cur_python%"
    echo "Probably the package for the version we want does not exist"
    echo "conda will change the Python version even if it was explicitly declared"
)

if "%DESIRED_CUDA%" == "cpu" (
    call conda list torch | findstr cuda || exit /b 0
	echo "The installed package is built for CUDA, the full package is"
	call conda list torch
) else (
    call conda list torch | findstr cuda%CUDA_VERSION% && exit /b 0
	echo "The installed package doesn't seem to be built for CUDA "%CUDA_VERSION_STR%
	echo "the full package is "
	call conda list torch
)
exit /b 1

:libtorch
echo "install libtorch from nightly"
if "%LIBTORCH_CONFIG%" == "debug" (
    set NAME_PREFIX=libtorch-win-shared-with-deps-debug
) else (
    set NAME_PREFIX=libtorch-win-shared-with-deps
)
if "%DESIRED_CUDA%" == "cu102" (
    set package_name=%NAME_PREFIX%-%NIGHTLIES_DATE_PREAMBLE%%DATE%.zip
) else (
    set package_name=%NAME_PREFIX%-%NIGHTLIES_DATE_PREAMBLE%%DATE%%%2B%DESIRED_CUDA%.zip
)
set libtorch_url="https://download.pytorch.org/libtorch/nightly/%DESIRED_CUDA%/%package_name%"
curl --retry 3 -k "%libtorch_url%" -o %package_name%
if ERRORLEVEL 1 exit /b 1

7z x %package_name% -otmp
if ERRORLEVEL 1 exit /b 1
