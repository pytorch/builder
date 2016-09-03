#!/bin/bash

# run this script from ~/ directory, i.e. to run it do:
#
# cd ~/ && builder/runjenkins.sh
set -e

# we'll first update, then call this script again, with 'stage2' argument
if [[ $1 == stage2 ]]; then {
  # start jenkins here
  # security doc: https://wiki.jenkins-ci.org/display/JENKINS/Quick+and+Simple+Security
  source ~/env/bin/activate
  eval $(python builder/readconfig.py)
  nohup env -i shared_secret=$shared_secret github_token=$github_token authbind --deep java -jar jenkins.war --httpsPort=443 --httpsKeyStore=jenkins.jks --httpsKeyStorePassword=jenkinspassword --argumentsRealm.passwd.jenkins=${jenkinspassword} --argumentsRealm.roles.jenkins=admin >jenkinsout.txt 2>&1 &
} else {
  # update git here
  pushd builder
  git pull
  popd
  builder/runjenkins.sh stage2
} fi

