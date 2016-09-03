#!/bin/bash

PROJECT=$1
GIT_COMMIT=$2
GIT_BRANCH=$3
GITHUB_TOKEN=$4

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

bash $DIR/jenkins/$PROJECT/build_nimbix.sh $PROJECT $GIT_COMMIT $GIT_BRANCH $GITHUB_TOKEN

