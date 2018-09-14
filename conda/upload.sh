#!/bin/bash

set -ex

# Upload linux conda packages (from inside the docker)
echo "Trying to upload conda packages from $HOST_PACKAGE_DIR"
if [[ -n "$HOST_PACKAGE_DIR" && -d "$HOST_PACKAGE_DIR" ]]; then
    ls "$HOST_PACKAGE_DIR" | xargs -I {} anaconda upload "$HOST_PACKAGE_DIR"/{}
else
    echo "Couldn't find $HOST_PACKAGE_DIR"
fi

# Upload linux conda packages (from outside the docker)
# TODO coordinate this location better
echo "Trying to upload conda packages from ${today}/conda_pkgs"
if [[ -n "$today" && -d "${today}/conda_pkgs" ]]; then
    ls "${today}/conda_pkgs" | xargs -I {} anaconda upload "${today}/conda_pkgs"/{} -c pytorch -u pytorch
else
    echo "Couldn't find ${today}/conda_pkgs"
fi

# Upload mac conda packages
echo "Trying to upload conda packages from $MAC_CONDA_FINAL_FOLDER"
if [[ -n "$MAC_CONDA_FINAL_FOLDER" && -d "$MAC_CONDA_FINAL_FOLDER" ]]; then
    ls "$MAC_CONDA_FINAL_FOLDER" | xargs -I {} anaconda upload "$MAC_CONDA_FINAL_FOLDER"/{}
else
    echo "Couldn't find $MAC_CONDA_FINAL_FOLDER"
fi
