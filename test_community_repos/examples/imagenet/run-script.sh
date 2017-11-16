pushd examples/imagenet
python main.py -a resnet18 $IMAGENET_ROOT --epochs 1
RETURN_CODE=$?
popd
exit $RETURN_CODE

