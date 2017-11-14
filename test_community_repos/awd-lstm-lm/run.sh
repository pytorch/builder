BASEDIR=$(dirname $0)
pushd $BASEDIR
# Also tests salesforce/pytorch-qrnn
git clone https://github.com/salesforce/awd-lstm-lm.git
./download-data.sh
./install-deps.sh
./run-script.sh
RETURN=$?
rm -rf awd-lstm-lm
popd
exit $RETURN

