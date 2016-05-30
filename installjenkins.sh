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
# wget https://raw.githubusercontent.com/hughperkins/torchunit/master/installjenkins.sh
# bash installjenkins.sh
#
# then, copy torchunit/config.yaml.templ to torchunit/config.yaml , and set a jenkins user password
# in it

sudo apt-get -y update
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

wget http://mirrors.jenkins-ci.org/war-stable/1.651.2/jenkins.war


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

# pull down git repo, contains run scripts etc
git clone https://github.com/hughperkins/torchunit

# start jenkins
torchunit/runjenkins.sh
sleep 40

# install git client
# this bit is all a bit beta :-P
curl -XPOST http://localhost:8080/pluginManager/installNecessaryPlugins -d '<install plugin="git@current" />'
sleep 40

JENKINSCLI=~/.jenkins/war/WEB-INF/jenkins-cli.jar
java -jar ${JENKINSCLI} -s http://127.0.0.1:8080/ safe-restart
sleep 40

# terminate jenkins
java -jar ${JENKINSCLI} -s http://127.0.0.1:8080/ safe-shutdown

# this enables security:
cp ~/torchunit/jenkins/config/config.xml ~/.jenkins

