export PYTORCH_BINARY_BUILD=1
export TH_BINARY_BUILD=1
git clone https://github.com/pytorch/pytorch
cd pytorch
/opt/python/cp27-cp27m/bin/pip install -r requirements.txt
/opt/python/cp27-cp27m/bin/python setup.py install
cd test/
LD_LIBRARY_PATH="$CMAKE_LIBRARY_PATH:$LD_LIBRARY_PATH" PYCMD=/opt/python/cp27-cp27m/bin/python ./run_test.sh
