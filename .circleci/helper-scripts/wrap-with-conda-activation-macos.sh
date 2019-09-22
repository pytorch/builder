#!/bin/bash -xe

COMMAND_TO_WRAP=$1

source $HOME/miniconda3/bin/activate

$COMMAND_TO_WRAP
