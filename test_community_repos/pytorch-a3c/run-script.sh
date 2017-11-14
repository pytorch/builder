pushd pytorch-a3c

# It trains in a loop forever. Kill it if it goes for 2m without dying
timeout 2m python3 main.py --env-name "PongDeterministic-v4" --max-episode-length 1
RETURN=$?
popd

# timeout returns 124 if there's a timeout
if [ $RETURN -ne 124 ]
then exit $RETURN
fi
