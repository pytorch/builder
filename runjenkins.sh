#!/bin/bash

# run this script from ~/torchunit directory, ie to run it do:
#
# torchunit/runjenkins.sh

# we'll first update, then call this script again, with 'stage2' argument
if [[ $1 == stage2 ]]; then {
  # start jenkins here
  java -jar jenkins.war --httpsPort=8443 --httpsCertificate=cert.pem --httpsPrivateKey=key.pem --httpPort=-1
} else {
  # update git here
  pushd torchunit
  git pull
  popd
  torchunit/runjenkins.sh stage2
} fi

