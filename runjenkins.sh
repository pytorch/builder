#!/bin/bash

# run this script from ~/torchunit directory, ie to run it do:
#
# torchunit/runjenkins.sh

# we'll first update, then call this script again, with 'stage2' argument
if [[ $1 == stage2 ]]; then {
  # start jenkins here
  # nohup java -jar jenkins.war --httpsPort=8443 --httpsCertificate=cert.pem --httpsPrivateKey=key.pem --httpPort=-1 >jenkinsout.txt 2>&1 &
  # security doc: https://wiki.jenkins-ci.org/display/JENKINS/Quick+and+Simple+Security
  source ~/env/bin/activate
  eval $(python torchunit/readconfig.py)
  nohup env -i java -jar jenkins.war --httpsPort=8443 --httpsCertificate=cert.pem --httpsPrivateKey=key.pem --argumentsRealm.passwd.jenkins=${jenkinspassword} --argumentsRealm.roles.jenkins=admin >jenkinsout.txt 2>&1 &
} else {
  # update git here
  pushd torchunit
  git pull
  popd
  torchunit/runjenkins.sh stage2
} fi

