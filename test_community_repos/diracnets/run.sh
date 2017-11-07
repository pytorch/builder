BASEDIR=$(dirname $0)
git clone https://github.com/szagoruyko/diracnets
pushd diracnets
# ../download_data.sh
../install-deps.sh
../run-script.sh
