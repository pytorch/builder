#!/bin/bash -e
# Derived from https://github.com/pytorch/pytorch/blob/05d1dcc14ce59561f3d8fcf993061df98d366230/.github/regenerate.sh

# Allows this script to be invoked from any directory:
cd "$(dirname "$0")"

python3 scripts/generate_ci_workflows.py
