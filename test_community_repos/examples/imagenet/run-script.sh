pushd examples/imagenet
if [ -z "$IMAGENET_ROOT" ]; then
    popd
    echo "IMAGENET_ROOT not set"
    exit 1
fi
python main.py -a resnet18 $IMAGENET_ROOT --epochs 1
RETURN_CODE=$?
popd
exit $RETURN_CODE

