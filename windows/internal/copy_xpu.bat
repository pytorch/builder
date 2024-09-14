copy "%XPU_BUNDLE_ROOT%\compiler\latest\bin\common_clang64.dll" pytorch\torch\lib
copy "%XPU_BUNDLE_ROOT%\compiler\latest\bin\intelocl64.dll" pytorch\torch\lib
copy "%XPU_BUNDLE_ROOT%\compiler\latest\bin\libmmd.dll" pytorch\torch\lib
copy "%XPU_BUNDLE_ROOT%\compiler\latest\bin\onnxruntime.1.12.22.721.dll" pytorch\torch\lib
copy "%XPU_BUNDLE_ROOT%\compiler\latest\bin\pi_level_zero.dll" pytorch\torch\lib
copy "%XPU_BUNDLE_ROOT%\compiler\latest\bin\pi_win_proxy_loader.dll" pytorch\torch\lib
copy "%XPU_BUNDLE_ROOT%\compiler\latest\bin\svml_dispmd.dll" pytorch\torch\lib
copy "%XPU_BUNDLE_ROOT%\compiler\latest\bin\sycl7.dll" pytorch\torch\lib
copy "%XPU_BUNDLE_ROOT%\tbb\latest\bin\tbb12.dll" pytorch\torch\lib

copy "%CONDA_LIB_PATH%\libiomp*5md.dll" pytorch\torch\lib
:: Should be set in build_pytorch.bat
copy "%libuv_ROOT%\bin\uv.dll" pytorch\torch\lib
