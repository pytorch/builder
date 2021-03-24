set VC_VERSION=
if "%VC_YEAR%" == "2017" if "%CUDA_VERSION%" == "92" (
    set VC_VERSION=14.13
    if not "%PYTORCH_BUILD_VERSION:1.6.=%" == "%PYTORCH_BUILD_VERSION%" if "%PYTORCH_BUILD_VERSION:dev=%" == "%PYTORCH_BUILD_VERSION%" (
        set VC_VERSION=14.11
    )
)

if not "%VC_VERSION%" == "" (
    set VSDEVCMD_ARGS=-vcvars_ver=%VC_VERSION%
)
if "%VC_YEAR%" == "2017" powershell windows/internal/vs2017_install.ps1 %VC_VERSION%
if errorlevel 1 exit /b 1
