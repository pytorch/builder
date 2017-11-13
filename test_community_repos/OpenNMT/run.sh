BASEDIR=$(dirname $0)
git clone https://github.com/OpenNMT/OpenNMT-py.git
pushd OpenNMT-py
../install-deps.sh
../run-script.sh
popd
rm -rf OpenNMT-py

