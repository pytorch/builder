#!/bin/bash

echo hello
echo this is running on the nimbix box
echo here is the commit hash $1
echo it should build torch, then clone this particular commit of cutorch, then run the unit tests
echo somehow the results should get back to jenkins....
echo probably the script htat launches it, should print the results back to the original http request perhaps?

