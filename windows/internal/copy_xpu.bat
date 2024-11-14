copy "%XPU_BUNDLE_ROOT%\compiler\latest\bin\libmmd.dll" pytorch\torch\lib
copy "%XPU_BUNDLE_ROOT%\compiler\latest\bin\svml_dispmd.dll" pytorch\torch\lib
copy "%XPU_BUNDLE_ROOT%\compiler\latest\bin\sycl8.dll" pytorch\torch\lib
copy "%XPU_BUNDLE_ROOT%\compiler\latest\bin\ur_adapter_level_zero.dll" pytorch\torch\lib
copy "%XPU_BUNDLE_ROOT%\compiler\latest\bin\ur_loader.dll" pytorch\torch\lib
copy "%XPU_BUNDLE_ROOT%\compiler\latest\bin\ur_win_proxy_loader.dll" pytorch\torch\lib

copy "%CONDA_LIB_PATH%\libiomp*5md.dll" pytorch\torch\lib
:: Should be set in build_pytorch.bat
copy "%libuv_ROOT%\bin\uv.dll" pytorch\torch\lib
