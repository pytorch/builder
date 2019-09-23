#!/usr/bin/env python

import os.path
import unittest
import subprocess
import sys


TIMEOUT = 2 * 60 * 60  # 2 hours


def run(command, timeout=None):
    """
    Returns (return-code, stdout, stderr)
    """
    completed = subprocess.run(command, stdout=subprocess.PIPE,
                                   stderr=subprocess.PIPE, shell=True,
                                   encoding="utf8", timeout=timeout)

    return completed.returncode, completed.stdout, completed.stderr


class TestRepos(unittest.TestCase):
    pass


def _test(cls, directory):
    command = os.path.join(directory, "run.sh")
    (rc, out, err) = run(command, TIMEOUT)
    cls.assertEqual(rc, 0, "Ran {}\nstdout:\n{}\nstderr:\n{}".format(
        command, out, err))


# Generate the tests, one for each repo
(rc, stdout, stderr) = run("find . -maxdepth 1 -type d -exec echo {} \;")
if rc is not 0:
    print("Couldn't execute find command")
    exit(1)

# Filter out '.', remove trailing ./
repos = stdout.split('\n')
repos = sorted([f[2:] for f in repos if len(f) > 2])
for f in repos:
    print("found {}".format(f))
    setattr(TestRepos, "test_" + f, lambda cls, f=f: _test(cls, f))


if __name__ == '__main__':
    unittest.main()
