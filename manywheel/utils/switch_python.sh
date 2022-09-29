#!/usr/bin/env bash

PYTHON_VERSION=${PYTHON_VERSION:-3.8}

# If given a python version like 3.6m or 2.7mu, convert this to the format we
# expect. The binary CI jobs pass in python versions like this; they also only
# ever pass one python version, so we assume that PYTHON_VERSION is not a list
# in this case
python_nodot="$(echo "${PYTHON_VERSION}" | tr -d m.u)"
case ${PYTHON_VERSION} in
  3.[6-7]*)
    pydir="cp${python_nodot}-cp${python_nodot}m"
    ;;
  # Should catch 3.8+
  3.*)
    pydir="cp${python_nodot}-cp${python_nodot}"
    ;;
esac

if [[ ! -d "/opt/python/${pydir}" ]]; then
    cat << EOF
::error::Requested python version (${PYTHON_VERSION}) not currently supported"
Please make an issue at https://github.com/pytorch/builder to add support for your requested version"
EOF
    exit 1
fi

echo "INFO: Adding /opt/python/${pydir} to PATH"
export PATH="/opt/python/${pydir}:${PATH}"
