#!/usr/bin/env bash


# NOTE: This is a shim for next versions of the pytorch binary build workflows
# TODO: Remove this once we fully move binary builds on master to GHA

SCRIPTPATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
bash ${SCRIPTPATH}/build_pytorch.sh
