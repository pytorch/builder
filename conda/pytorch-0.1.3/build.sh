export CMAKE_LIBRARY_PATH=$PREFIX/lib:$PREFIX/include:$CMAKE_LIBRARY_PATH 
export CMAKE_PREFIX_PATH=$PREFIX

if [[ "$OSTYPE" == "darwin"* ]]; then
    MACOSX_DEPLOYMENT_TARGET=10.9 python setup.py install
    install_name_tool -change libmkl_intel_lp64.dylib "@rpath/../../../../libmkl_intel_lp64.dylib" $SP_DIR/torch/lib/libTH.dylib
    install_name_tool -change libmkl_intel_thread.dylib "@rpath/../../../../libmkl_intel_thread.dylib" $SP_DIR/torch/lib/libTH.dylib
    install_name_tool -change libmkl_core.dylib "@rpath/../../../../libmkl_core.dylib" $SP_DIR/torch/lib/libTH.dylib
    install_name_tool -change libiomp5.dylib "@rpath/../../../../libiomp5.dylib" $SP_DIR/torch/lib/libTH.dylib
else
    python setup.py install
fi
