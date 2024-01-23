copy "%CONDA_LIB_PATH%\libiomp*5md.dll" pytorch\torch\lib
:: Should be set in build_pytorch.bat
copy "%libuv_ROOT%\bin\uv.dll" pytorch\torch\lib

IF "%PACKAGE_TYPE%"=="libtorch" (
    copy "%CONDA_LIB_PATH%\mkl_intel_thread.1.dll" pytorch\torch\lib
    copy "%CONDA_LIB_PATH%\mkl_core.1.dll" pytorch\torch\lib
)
