#!/usr/bin/env python3

import os.path
import unittest
import subprocess
import sys
import os


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


def generate_test_objects(target_directory):
    """
    Generate the tests, one for each repo
    """
    repos = sorted([os.path.normpath(os.path.join(target_directory, o)) for o in os.listdir(target_directory) if os.path.isdir(os.path.join(target_directory, o))])
    for f in repos:
        print("found {}".format(f))
        setattr(TestRepos, "test_" + f, lambda cls, f=f: _test(cls, f))


if __name__ == '__main__':
    generate_test_objects('examples')
    unittest.main()
