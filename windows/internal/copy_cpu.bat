copy "%CONDA_LIB_PATH%\libiomp*5md.dll" pytorch\torch\lib

:: Should be set in build_pytorch.bat
if "%CROSS_COMPILE_ARM64%" == "" (
    copy "%libuv_ROOT%\bin\uv.dll" pytorch\torch\lib
)
