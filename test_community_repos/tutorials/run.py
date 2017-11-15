import re
import subprocess
import sys
import argparse

PY3 = sys.version_info >= (3, 0)


blacklist = [
    "./advanced_source/super_resolution_with_caffe2.py",
    # The docker image's python has some trouble with decoding unicode
    "./intermediate_source/char_rnn_classification_tutorial.py",
]
visual = [
    "./advanced_source/neural_style_tutorial.py",
    "./beginner_source/blitz/cifar10_tutorial.py",
    "./beginner_source/data_loading_tutorial.py",
    "./beginner_source/transfer_learning_tutorial.py",
    "./intermediate_source/char_rnn_generation_tutorial.py",
    "./intermediate_source/reinforcement_q_learning.py",
    "./intermediate_source/seq2seq_translation_tutorial.py",
    "./intermediate_source/spatial_transformer_tutorial.py",
]


def run(command):
    """
    Returns (return-code, stdout, stderr)
    """
    p = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)
    output, err = p.communicate()
    rc = p.returncode
    if PY3:
        output = output.decode("ascii")
        err = err.decode("ascii")
    return (rc, output, err)


def main():
    parser = argparse.ArgumentParser(
            description="Run all pytorch tutorials")
    parser.add_argument('--visual', dest='visual', 
            action='store_true',
            default=False,
            help='Run the tutorials that rely on a GUI. Default: False')
    parser.add_argument('--py', dest='python', 
            action='store',
            default='python',
            help='the python binary. Default: python')
    parser.add_argument('--all', dest='all', 
            action='store_true',
            default=False,
            help='Run all tutorials, include visual and blacklisted ones.')

    args = parser.parse_args()
    run_visual = args.visual

    (rc, stdout, stderr) = run("find . -type f | grep -P 'source.+py$'")
    if rc is not 0:
        print("Couldn't execute find")
        exit(1)

    files = stdout.split('\n')
    files = [f for f in files if len(f) > 0]
    failed = []
    warns = []

    python = args.python

    for f in files:
        if not args.all and f in blacklist:
            print("skipping {}".format(f))
            continue
        if not args.all and not run_visual and f in visual:
            print("skipping {} b/c --visual was not set".format(f))
            continue

        (rc, out, err) = run("{} {}".format(python, f))
        fail_msg = ""
        if rc is not 0:
            failed.append((rc, out, err, f))
            fail_msg = " [FAILED]"
        if rc is 0 and len(err) is not 0:
            warns.append((rc, out, err, f))
            fail_msg = " [WARNINGS]"
        print("testing {}{}".format(f, fail_msg))

    if len(failed) is 0 and len(warns) is 0:
        print("All tutorials ran successfully")
        exit(0)

    for (rc, out, err, f) in warns:
        print("-" * 50)
        print("[WARNINGS] {} {} had warnings:".format(python, f))
        print("return code: {}\nstdout:\n{}\nstderr:\n{}\n".format(
            rc, out, err))

    if len(failed) is 0:
        exit(0)

    for (rc, out, err, f) in failed:
        print("-" * 50)
        print("[FAILED] {} {} failed with the following:".format(python, f))
        print("return code: {}\nstdout:\n{}\nstderr:\n{}\n".format(
            rc, out, err))

    exit(1)


if __name__ == '__main__':
    main()
