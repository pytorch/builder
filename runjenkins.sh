#!/bin/bash

# run this script from ~/builder directory, ie to run it do:
#
# builder/runjenkins.sh

# we'll first update, then call this script again, with 'stage2' argument
if [[ $1 == stage2 ]]; then {
  # start jenkins here
  # nohup java -jar jenkins.war --httpsPort=443 --httpsCertificate=cert.pem --httpsPrivateKey=key.pem --httpPort=-1 >jenkinsout.txt 2>&1 &
  # security doc: https://wiki.jenkins-ci.org/display/JENKINS/Quick+and+Simple+Security
  source ~/env/bin/activate
  eval $(python builder/readconfig.py)
  HTTPS_CERT_DIR="/etc/letsencrypt/live/build.pytorch.org"
  nohup env -i shared_secret=$shared_secret java -jar jenkins.war --httpsPort=443 --httpsCertificate=$HTTPS_CERT_DIR/cert.pem --httpsPrivateKey=HTTPS_CERT_DIR/privkey.pem --argumentsRealm.passwd.jenkins=${jenkinspassword} --argumentsRealm.roles.jenkins=admin >jenkinsout.txt 2>&1 &
} else {
  # update git here
  pushd builder
  git pull
  popd
  builder/runjenkins.sh stage2
} fi

