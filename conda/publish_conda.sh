#!/bin/bash

set -e

# Publish conda packages from pytorch-nightly to pytorch

if [[ -z "$1" ]]; then
  echo "Usage ./publish_conda.sh torchaudio==0.3.0"
  exit 1
fi

export PLATFORMS=('linux-64' 'osx-64')

# TODO: get rid of the version suffixes
export VERSION_SUFFIXES=('' '+cpu' '+cu92' '+c100')

for platform in "${PLATFORMS[@]}"; do
  for suffix in "${VERSION_SUFFIXES[@]}"; do
    for url in $(conda search --platform "$platform" "$1$suffix[channel=pytorch-nightly]" --json | jq -r '.[][].url'); do
      file="$(basename "$url")"
      curl -o "$file" "$url"
      anaconda upload -u pytorch "$file"
    done
  done
done
