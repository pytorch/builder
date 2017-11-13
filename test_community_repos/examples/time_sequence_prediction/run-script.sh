pushd examples/time_sequence_prediction
python generate_sine_wave.py
python train.py
RETURN_CODE=$?
popd
exit $RETURN_CODE

