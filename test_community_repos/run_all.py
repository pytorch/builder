import unittest
import subprocess
import sys

PY3 = sys.version_info >= (3, 0)
TIMEOUT = 2 * 60 * 60  # 2 hours


def run(command, timeout=None):
    """
    Returns (return-code, stdout, stderr)
    """
    if PY3:
        completed = subprocess.run(command, stdout=subprocess.PIPE,
                                   stderr=subprocess.PIPE, shell=True,
                                   encoding="utf8", timeout=timeout)
        return completed.returncode, completed.stdout, completed.stderr

    # Python 2...
    if timeout is not None:
        print("WARNING: timeout not supported for python 2")
    p = subprocess.Popen(command, stdout=subprocess.PIPE,
                         stderr=subprocess.PIPE, shell=True)
    output, err = p.communicate()
    rc = p.returncode
    return rc, output, err


class TestRepos(unittest.TestCase):
    pass


def _test(cls, directory):
    command = "bash {}/run.sh".format(directory)
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
