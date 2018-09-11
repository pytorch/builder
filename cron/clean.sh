#!/bin/bash

set -ex

if [[ -z "$NIGHTLIES_FOLDER" ]]; then
    echo "Env variable NIGHTLIES_FOLDER must be set"
    exit 1
fi
if [[ -z "$NIGHTLIES_DATE" ]]; then
    export NIGHTLIES_DATE="$(date +%Y_%m_%d)"
fi
today="$NIGHTLIES_FOLDER/$NIGHTLIES_DATE"

# The Github repos had their permissions changed to read-only to prevent
# concurrent builds from interfering with each other
chmod -R 755 "${today}/pytorch" || true
chmod -R 755 "${today}/builder" || true

# Remove only the repos for now
rm -rf "${today}/pytorch"
rm -rf "${today}/builder"
