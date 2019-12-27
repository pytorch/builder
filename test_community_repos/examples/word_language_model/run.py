#!/usr/bin/env python
import re
import subprocess
import sys
import argparse
import os
PY3 = sys.version_info >= (3, 0)

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

def find_val(stdout, key):
    words = stdout.split(key)
    out = words[1].split("\n")
    return float(out[0].lstrip().rstrip())

def main():
    threshold = float(sys.argv[1])
    cuda_arg=""
    if(len(sys.argv) == 3 and sys.argv[2] == "--cuda"):
        cuda_arg="--cuda"

    (rc, stdout, stderr) = run("git clone https://github.com/pytorch/examples.git")
    if rc is not 0:
        print("Couldn't clone examples.git")
        exit(1)
    (rc, stdout, stderr) = run("./download-data.sh")
    if rc is not 0:
        print("Couldn't download data")
        exit(1)
    else:
        print("downloaded data")

    (rc, stdout, stderr) = run("./install-deps.sh")
    if rc is not 0:
        print("Couldn't install dependencies")
        exit(1)
    else:
        print("installed dependencies")

    (rc, stdout, stderr) = run("python examples/word_language_model/main.py --data ./examples/word_language_model/data/wikitext-2 " + cuda_arg + " --epochs 1")
    if rc is not 0:
        print("Couldn't run the model", stdout, stderr)
        exit(1)
    else:
        print(stdout)
        valid_ppl = find_val(stdout, "valid ppl")
        print("valid_ppl: ", valid_ppl)
        if(valid_ppl < threshold):
            print("valid_ppl is less than", threshold)
            exit(1)
        # test_ppl = find_val(stdout, "test ppl")
        # print("test_ppl: ", test_ppl)

    (rc, stdout, stderr) = run("python examples/word_language_model/main.py --data ./examples/word_language_model/data/wikitext-2 " + cuda_arg + " --epochs 1 --tied")
    if rc is not 0:
        print("Couldn't run the model", stdout, stderr)
        exit(1)
    else:
        print(stdout)
        valid_ppl = find_val(stdout, "valid ppl")
        print("valid_ppl: ", valid_ppl)
        if(valid_ppl < threshold):
            print("valid_ppl is less than", threshold)
            exit(1)
        # test_ppl = find_val(stdout, "test ppl")
        # print("test_ppl: ", test_ppl)

    (rc, stdout, stderr) = run("rm -rf examples")
    if rc is not 0:
        print("Couldn't remove examples")
        exit(1)

    exit(0)

if __name__ == '__main__':
    main()
