cp $RECIPE_DIR/makefile.inc .
cp $RECIPE_DIR/setup.py .

make -j 10
make -C python
# make -C tests tests
# make tests requires folder name to be faiss, now name is work

rm -f python/_swigfaiss_gpu.so

# not necessary
#sed -i "s/from ._swigfaiss/from .swigfaiss/g" faiss.py

find $SP_DIR/torch -name "*.so*" -maxdepth 1 -type f | while read sofile; do
    echo "Setting rpath of $sofile to " '$ORIGIN:$ORIGIN/../../..'
    patchelf --set-rpath '$ORIGIN:$ORIGIN/../../..' $sofile
    patchelf --print-rpath $sofile
done

python setup.py install
