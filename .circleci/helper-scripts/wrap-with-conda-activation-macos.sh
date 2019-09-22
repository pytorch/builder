#!/bin/bash -xe

COMMAND_TO_WRAP=$1
shift

source $HOME/miniconda3/bin/activate

$COMMAND_TO_WRAP
