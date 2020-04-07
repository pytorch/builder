if "%VC_YEAR%" == "2017" set VSDEVCMD_ARGS=-vcvars_ver=14.11
if "%VC_YEAR%" == "2017" powershell windows/internal/vs_install.ps1
if errorlevel 1 exit /b 1

call windows/internal/cuda_install.bat
if errorlevel 1 exit /b 1

call windows/internal/nightly_defaults.bat Conda
if errorlevel 1 exit /b 1

set PYTORCH_FINAL_PACKAGE_DIR=%CD%\windows\output
if not exist "%PYTORCH_FINAL_PACKAGE_DIR%" mkdir %PYTORCH_FINAL_PACKAGE_DIR%

bash ./conda/build_pytorch.sh %CUDA_VERSION% %PYTORCH_BUILD_VERSION% %PYTORCH_BUILD_NUMBER%
if errorlevel 1 exit /b 1
