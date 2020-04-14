if "%VC_YEAR%" == "2017" if "%CUDA_VERSION%" == "92" set VSDEVCMD_ARGS=-vcvars_ver=14.11
if "%VC_YEAR%" == "2017" powershell windows/internal/vs_install.ps1
if errorlevel 1 exit /b 1

call windows/internal/cuda_install.bat
if errorlevel 1 exit /b 1

call windows/internal/nightly_defaults.bat Wheels
if errorlevel 1 exit /b 1

call windows/build_pytorch.bat %CUDA_VERSION% %PYTORCH_BUILD_VERSION% %PYTORCH_BUILD_NUMBER%
if errorlevel 1 exit /b 1
