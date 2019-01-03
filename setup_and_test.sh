set -ex

SOURCE_DIR=$(cd $(dirname $0) && pwd)

# Written for circleci binary builds, to manage setting up the python env
# before calling run_tests.sh

# Parameters
#############################################################################
if [[ -z "$PACKAGE_TYPE" || -z "$DESIRED_PYTHON" || -z "$PYVER_SHORT" || -z "$CUMAJMIN" || -z "$PYTORCH_FINAL_PACKAGE_DIR" ]]; then
  echo "The env variable PACKAGE_TYPE must be set to 'conda' or 'manywheel' or 'libtorch'"
  echo "The env variable DESIRED_PYTHON must be set like 'cp27-cp27mu'"
  echo "The env variable PYVER_SHORT must be set like '2.7'"
  echo "The env variable CUMAJMIN must be set like 'cpu' or 'cu80' etc"
  echo "The env variable PYTORCH_FINAL_PACKAGE_DIR must be set to a directory"
  exit 1
fi
py_nodot="$(echo $PYVER_SHORT | tr -d '.')"

# Create Python env for testing
#############################################################################
if [[ "$PACKAGE_TYPE" == manywheel ]]; then
  export PATH="/opt/python/$DESIRED_PYTHON/bin:$PATH"
elif [[ "$PACKAGE_TYPE" == conda ]]; then
  source deactivate || true
  conda create -yn "setuptest$py_nodot" python=$py_nodot
  source activate "setuptest$py_nodot"
else
  echo "This script does not handle $PACKAGE_TYPE packages"
  exit 1
fi

# Install package
#############################################################################
package="$(ls $PYTORCH_FINAL_PACKAGE_DIR)"
if [[ "$PACKAGE_TYPE" == manywheel ]]; then
  pip install $package
else
  conda install -y $package
fi

# Test the package
#############################################################################
"$SOURCE_DIR/run_tests.sh" "$PACKAGE_TYPE" "$PYVER_SHORT" "$CUMAJMIN"
