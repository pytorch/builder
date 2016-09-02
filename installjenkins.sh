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
# wget https://raw.githubusercontent.com/pytorch/builder/master/bootstrap.sh
# bash bootstrap.sh
#
# 2.
# copy builder/config.yaml.templ to builder/config.yaml , and set a jenkins user password
# in it
#
# 3.
# bash builder/installjenkins.sh

set -e

cd ~

sudo apt-get -y update
sudo apt-get -y upgrade
sudo apt-get install -y git openjdk-7-jre-headless htop iotop tmux
sudo apt-get install -y python3.4-dev python-virtualenv python-wheel
sudo apt-get install -y authbind

sudo touch /etc/authbind/byport/443
sudo chown $USER /etc/authbind/byport/443
sudo chmod 755 /etc/authbind/byport/443

rm -rf ~/env
virtualenv -p python3 ~/env
source ~/env/bin/activate
pip install -U pip
pip install -U wheel
pip install -U setuptools
pip install pyyaml
pip install requests

if ls ~/.jenkins >/dev/null 2>&1;
then
    echo "WARNING WARNING: removing existing jenkins and it's configuration files"
    sleep 10;
    rm jenkins.war
    rm -rf ~/.jenkins
fi
wget -c http://mirrors.jenkins-ci.org/war-stable/2.7.2/jenkins.war


if ! ls /etc/letsencrypt/live/build.pytorch.org >/dev/null 2>&1;
then
    wget -c https://dl.eff.org/certbot-auto
    chmod a+x certbot-auto
    ./certbot-auto
    ./certbot-auto certonly
    sudo chmod 711 "/etc/letsencrypt"
    sudo chmod 711 "/etc/letsencrypt/live"
    sudo chmod 711 "/etc/letsencrypt/archive"
    rm -f keys.pkcs12
    rm -f jenkins.jks
    openssl pkcs12 -inkey /etc/letsencrypt/live/build.pytorch.org/privkey.pem -in /etc/letsencrypt/live/build.pytorch.org/cert.pem  -export -out keys.pkcs12 -passout "pass:jenkinspassword"
    keytool -importkeystore -srckeystore keys.pkcs12 -srcstoretype pkcs12 -destkeystore jenkins.jks -srcstorepass jenkinspassword -deststorepass jenkinspassword
    rm -f keys.pkcs12
fi

# start jenkins
builder/runjenkins.sh
sleep 40

# install git client
# this bit is all a bit beta :-P
echo installing git plugin
CRUMB=$(curl -s 'http://localhost:8080/crumbIssuer/api/xml?xpath=concat(//crumbRequestField,":",//crumb)')
echo $CRUMB
curl -H $CRUMB -XPOST http://localhost:8080/pluginManager/installNecessaryPlugins -d '<install plugin="git@current" />'
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
cp ~/builder/jenkins/config/config.xml ~/.jenkins

