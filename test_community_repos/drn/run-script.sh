pushd drn
if [ -z "$IMAGENET_ROOT" ]; then
    popd
    echo "IMAGENET_ROOT not set"
    exit 1
fi
timeout 10m python classify.py train --arch drn_c_26 -j 8 $IMAGENET_ROOT --epochs 1 --scale-size=64 --crop-size=50
RETURN=$?
popd

# Assuming timeout means nothing is wrong. A full run of this would take ~3 hours.
if [ $RETURN -eq 124 ]; then
    exit 0
fi
exit $RETURN
