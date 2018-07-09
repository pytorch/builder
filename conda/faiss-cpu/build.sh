cp $RECIPE_DIR/setup.py .

MAJOR_VERSION=`python -c "import sys;print(sys.version_info[0])"`
./configure --with-python-config=python${MAJOR_VERSION}-config
make clean
make -j 10
make -C python
# make -C tests tests
# no need to build these tests in conda-bld. make tests requires folder name to be faiss, now name is work

rm -f python/_swigfaiss_gpu.so

python setup.py install
