cp $RECIPE_DIR/makefile.inc .
cp $RECIPE_DIR/setup.py .

make -j 10
make -C gpu -j 10
make -C python gpu
make -C python

# not necessary
# sed -i "s/from swigfaiss/from .swigfaiss/g" faiss.py

find $SP_DIR/torch -name "*.so*" -maxdepth 1 -type f | while read sofile; do
    echo "Setting rpath of $sofile to " '$ORIGIN:$ORIGIN/../../..'
    patchelf --set-rpath '$ORIGIN:$ORIGIN/../../..' $sofile
    patchelf --print-rpath $sofile
done

python setup.py install
