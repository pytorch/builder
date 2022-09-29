#!/usr/bin/env bash

if [[ ${PYTHON_VERSION:-} != "" ]]; then
  echo "+ INFO: Switching python version to ${PYTHON_VERSION}"
  # Switch python version if PYTHON_VERSION env variable set
  PYTHON_VERSION="${PYTHON_VERSION}" /opt/python/switch_python.sh
fi
