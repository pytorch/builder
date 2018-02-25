set VC_PATH=x86
if "%ARCH%"=="64" (
   set VC_PATH=x64
)

set MSC_VER=2017

rem :: This should always be present for VC installed with VS.  Not sure about VC installed with Visual C++ Build Tools 2015
rem FOR /F "usebackq tokens=3*" %%A IN (`REG QUERY "HKEY_LOCAL_MACHINE\Software\Microsoft\DevDiv\VC\Servicing\14.0\IDE.x64" /v UpdateVersion`) DO (
rem     set SP=%%A
rem     )

rem if not "%SP%" == "%PKG_VERSION%" (
rem    echo "Version detected from registry: %SP%"
rem    echo    "does not match version of package being built (%PKG_VERSION%)"
rem    echo "Do you have current updates for VS 2015 installed?"
rem    exit 1
rem )


REM ========== REQUIRES Win 10 SDK be installed, or files otherwise copied to location below!
robocopy "C:\Program Files (x86)\Windows Kits\10\Redist\ucrt\DLLs\%VC_PATH%"  "%LIBRARY_BIN%" *.dll /E
robocopy "C:\Program Files (x86)\Windows Kits\10\Redist\ucrt\DLLs\%VC_PATH%"  "%PREFIX%" *.dll /E
if %ERRORLEVEL% GEQ 8 exit 1

REM ========== This one comes from visual studio 2017
set "UPDATE_VER=14.11.25325"
set "VC_VER=141"
set "BT_ROOT=C:\Program Files (x86)\Microsoft Visual Studio\%MSC_VER%\Community"
set "REDIST_ROOT=%BT_ROOT%\VC\Redist\MSVC\%UPDATE_VER%\onecore\%VC_PATH%"
robocopy "%REDIST_ROOT%\Microsoft.VC%VC_VER%.CRT" "%LIBRARY_BIN%" *.dll /E
if %ERRORLEVEL% LSS 8 exit 0
robocopy "%REDIST_ROOT%\Microsoft.VC%VC_VER%.CRT" "%PREFIX%" *.dll /E
if %ERRORLEVEL% LSS 8 exit 0
robocopy "%REDIST_ROOT%\Microsoft.VC%VC_VER%.OpenMP" "%LIBRARY_BIN%" *.dll /E
if %ERRORLEVEL% LSS 8 exit 0
robocopy "%REDIST_ROOT%\Microsoft.VC%VC_VER%.OpenMP" "%PREFIX%" *.dll /E
if %ERRORLEVEL% LSS 8 exit 0
