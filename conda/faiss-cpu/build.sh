cp $RECIPE_DIR/makefile.inc .
cp $RECIPE_DIR/setup.py .

make tests/test_blas -j $(nproc)
make -j $(nproc)
make py

rm -f python/_swigfaiss_gpu.so

sed -i "s/from swigfaiss/from .swigfaiss/g" faiss.py

find $SP_DIR/torch -name "*.so*" -maxdepth 1 -type f | while read sofile; do
    echo "Setting rpath of $sofile to " '$ORIGIN:$ORIGIN/../../..'
    patchelf --set-rpath '$ORIGIN:$ORIGIN/../../..' $sofile
    patchelf --print-rpath $sofile
done

python setup.py install
