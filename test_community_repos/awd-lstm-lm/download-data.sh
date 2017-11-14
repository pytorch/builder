apt-get -qq update
apt-get -qq -y install unzip wget
pushd awd-lstm-lm
./getdata.sh
popd
