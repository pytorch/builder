#!/bin/bash

#set -e

# Publish conda packages from pytorch-nightly to pytorch

if [[ -z "$1" ]]; then
  echo "Usage ./publish_conda.sh torchaudio==0.3.0"
  exit 1
fi

export PLATFORMS=('linux-64' 'osx-64')

for platform in "${PLATFORMS[@]}"; do
  for url in $(conda search --platform "$platform" "$1[channel=pytorch-nightly]" --json | jq -r '.[][].url'); do
    echo "$url"
    file="$(basename "$url")"
    curl -L -o "$file" "$url"
    anaconda upload -u pytorch "$file"
  done
done
