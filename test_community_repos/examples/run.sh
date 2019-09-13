#!/bin/bash -xe

BASEDIR=$(dirname $0)
pushd $BASEDIR

for file in */ ; do
    echo "Testing $file";
    for script in $file/run.sh ; do
        $script
    done
    echo "Test passed $file";
done

popd
