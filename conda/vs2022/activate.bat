:: Set env vars that tell distutils to use the compiler that we put on path
set DISTUTILS_USE_SDK=1
set MSSdk=1

set "VS_VERSION=17.4"
set "VS_MAJOR=17"
set "VC_YEAR=2022"
set "VC_VERSION_LOWER=17"
set "VC_VERSION_UPPER=18"

set "MSYS2_ARG_CONV_EXCL=/AI;/AL;/OUT;/out"
set "MSYS2_ENV_CONV_EXCL=CL"

:: For Python 3.5+, ensure that we link with the dynamic runtime.  See
:: http://stevedower.id.au/blog/building-for-python-3-5-part-two/ for more info
set "PY_VCRUNTIME_REDIST=%PREFIX%\\bin\\vcruntime143.dll"

if not "%VS15INSTALLDIR%" == "" if exist "%VS15INSTALLDIR%\VC\Auxiliary\Build\vcvarsall.bat" (
    set "VSINSTALLDIR=%VS15INSTALLDIR%\"
    goto :vswhere
)

for /f "usebackq tokens=*" %%i in (`"%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe" -legacy -products * -version [%VC_VERSION_LOWER%^,%VC_VERSION_UPPER%^) -property installationPath`) do (
    if exist "%%i" if exist "%%i\VC\Auxiliary\Build\vcvarsall.bat" (
        set "VSINSTALLDIR=%%i\"
        goto :vswhere
    )
)

:vswhere

:: Shorten PATH to avoid the `input line too long` error.
set MyPath=%PATH%

setlocal EnableDelayedExpansion

set TempPath="%MyPath:;=";"%"
set var=
for %%a in (%TempPath%) do (
    if exist %%~sa (
        set "var=!var!;%%~sa"
    )
)

set "TempPath=!var:~1!"
endlocal & set "PATH=%TempPath%"

:: Shorten current directory too
for %%A in (.) do cd "%%~sA"

:: other things added by install_activate.bat at package build time
