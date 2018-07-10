cp $RECIPE_DIR/setup.py .

MAJOR_VERSION=`python -c "import sys;print(sys.version_info[0])"`
./configure --with-python-config=python${MAJOR_VERSION}-config
make clean
make -j 10
make -C gpu -j 10
make -C python gpu
make -C python

python setup.py install
