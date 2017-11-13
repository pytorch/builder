BASEDIR=$(dirname $0)
pushd $BASEDIR
curl -o cocotrain2014.zip http://images.cocodataset.org/zips/train2014.zip
# TODO: unzip isn't installed on the docker images, python is slow
python unzip.py cocotrain2014.zip
popd

