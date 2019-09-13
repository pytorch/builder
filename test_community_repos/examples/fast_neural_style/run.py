import re
import subprocess 
import sys
import os

PY3 = sys.version_info >= (3, 0)


def run(command, timeout):
    """
    Returns (return-code, stdout, stderr)
    """
    p = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)
    output, err = p.communicate(timeout=timeout)
    rc = p.returncode
    if PY3:
        output = output.decode("ascii")
        err = err.decode("ascii")
    return rc, output, err


# data lives in $BASEDIR/cocotrain2014/
command_args = [
    'python',
    'examples/fast_neural_style/neural_style/neural_style.py',
    'train',
    '--dataset',
    'cocotrain2014',
    '--style-image',
    'examples/fast_neural_style/images/style-images/mosaic.jpg',
    '--save-model-dir',
    './saved_models',
    '--epochs',
    '1',
    '--image-size=128',
    '--cuda',
    '0' if os.environ.get("CU_VERSION") == 'cpu' else '1',
]


command = " ".join(command_args)


def main():
    # Test: run one epoch of fast neural style training. Warning: takes a while (half an hour?)
    (rc, stdout, err) = subprocess.check_output(command, shell=True)
    print("stdout:\n", stdout, "stderr:\n", err)
    if rc is not 0:
        sys.exit(rc)

    # Processes the output for losses
    matches = re.findall('total: (\d+\.\d*)', stdout)
    if len(matches) is 0:
        print("error: unexpected output:", stdout)
        sys.exit(1)
    losses = [float(m) for m in matches]

    # Smoke test: assert losses are decreasing
    prev = float('Inf')
    for loss in losses:
        if loss > prev:
            print("error: non-decreasing loss:", losses)
            sys.exit(1)


if __name__ == '__main__':
    main()
