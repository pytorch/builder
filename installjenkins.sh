#!/bin/bash

# this will install jenkins, onto a new t2.micro ec2 ubuntu 14.04 instance
#
# thats the goal
#
# so far, it's just this declaration of a goal, and no actual script :-D
#
# current idea for how to run this in the instance:
# 
# in the instance ssh, paste and run:
#
# 1.
# wget https://raw.githubusercontent.com/hughperkins/torchunit/master/bootstrap.sh
# bash bootstrap.sh
#
# 2.
# copy torchunit/config.yaml.templ to torchunit/config.yaml , and set a jenkins user password
# in it
#
# 3.
# bash torchunit/installjenkins.sh

cd ~

#sudo apt-get -y update
sudo apt-get -y upgrade
sudo apt-get install -y git openjdk-7-jre-headless htop iotop tmux
sudo apt-get install -y python3.4-dev python-virtualenv python-wheel

virtualenv -p python3 ~/env
source ~/env/bin/activate
pip install -U pip
pip install -U wheel
pip install -U setuptools
pip install pyyaml
pip install requests

wget http://mirrors.jenkins-ci.org/war-stable/2.7.2/jenkins.war


# self-signed cert.  ok-ish to use self-signed for now
# from https://github.com/hughperkins/howto-jenkins-ssl

openssl genrsa -out key.pem
# create answer file:
cat <<EOF>infile
US




jenkins.torch.ch



EOF
openssl req -new -key key.pem -out csr.pem <infile
openssl x509 -req -days 9999 -in csr.pem -signkey key.pem -out cert.pem
rm csr.pem

# start jenkins
torchunit/runjenkins.sh
sleep 40

# install git client
# this bit is all a bit beta :-P
echo installing git plugin
curl -XPOST http://localhost:8080/pluginManager/installNecessaryPlugins -d '<install plugin="git@current" />'
echo sleeping...
sleep 40

echo bouncing...
JENKINSCLI=~/.jenkins/war/WEB-INF/jenkins-cli.jar
java -jar ${JENKINSCLI} -s http://127.0.0.1:8080/ safe-restart
echo sleeping...
sleep 40

# terminate jenkins
echo shutting jenkins down
java -jar ${JENKINSCLI} -s http://127.0.0.1:8080/ safe-shutdown

# this enables security:
cp ~/torchunit/jenkins/config/config.xml ~/.jenkins

