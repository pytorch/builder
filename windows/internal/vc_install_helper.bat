set VC_VERSION=
if "%VC_YEAR%" == "2017" if "%CUDA_VERSION%" == "92" (
    set VC_VERSION=14.13
    if not "%PYTORCH_BUILD_VERSION:1.6.=%" == "%PYTORCH_BUILD_VERSION%" if "%PYTORCH_BUILD_VERSION:dev=%" == "%PYTORCH_BUILD_VERSION%" (
        set VC_VERSION=14.11
    )
)
if "%VC_YEAR%" == "2019" set VC_VERSION=14.28.29333
if not "%VC_VERSION%" == "" (
    set VSDEVCMD_ARGS=-vcvars_ver=%VC_VERSION%
)
if "%VC_YEAR%" == "2017" powershell windows/internal/vs2017_install.ps1 %VC_VERSION%
if "%VC_YEAR%" == "2019" powershell windows/internal/vs2019_install.ps1 %VC_VERSION%

set VC_VERSION_LOWER=16
set VC_VERSION_UPPER=17
IF "%VC_YEAR%" == "2017" (
    set VC_VERSION_LOWER=15
    set VC_VERSION_UPPER=16
)

for /f "usebackq tokens=*" %%i in (`"%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe"  -products Microsoft.VisualStudio.Product.BuildTools -version [%VC_VERSION_LOWER%^,%VC_VERSION_UPPER%^) -property installationPath`) do (
    if exist "%%i" if exist "%%i\VC\Auxiliary\Build\vcvarsall.bat" (
        set "VSINSTALLDIR=%%i"
        goto vswhere
    )
)

:vswhere
echo "Setting VSINSTALLDIR to %VSINSTALLDIR%"

if errorlevel 1 exit /b 1
