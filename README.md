# pytorch builder

Scripts to build pytorch in Jenkins / Nimbix for continuous integration and building binaries

# Getting started

* Setup an ec2 machine according to instructions from docs/ec2instance.md
* Sign up for NIMBIX  according to instructions from docs/nimbixsignup.md
* Create a github bot called "pytorchbot" according to instructions from docs/githubconfiguration.md
* On the ec2 machine, [setup an ssh key](https://help.github.com/articles/generating-an-ssh-key/) and add it to the "pytorchbot" github account
* SSH into the ec2 instance, and run:

```bash
cd ~/
sudo apt-get update -y
sudo apt-get install -y git
git clone git@github.com:pytorch/builder.git
cp builder/config.yaml.templ builder/config.yaml
```

* Change the jenkinspassword and shared_secret in builder/config.yaml
* Then run this and follow instructions:

```bash
bash builder/installjenkins.sh
```

* Then start jenkins

```bash
bash builder/runjenkins.sh
```

* Follow the instructions in docs/jenkins.md
* Follow the instructions in docs/wrapperinstancesetup.md

* Finally, run these commands so that http://build.pytorch.org gets forwarded to https:// automatically
```bash
sudo apt-get install -y nginx
sudo service nginx stop
sudo rm /etc/nginx/sites-enabled/default
cat <<EOF | sudo tee /etc/nginx/sites-available/redirect-https
server {
    listen         80;
	return 302 https://\$host\$request_uri;
}
EOF
sudo ln -sf /etc/nginx/sites-available/redirect-https /etc/nginx/sites-enabled/redirect-https
sudo service nginx start
```

 * email notifications
 ```
 sudo apt-get install mailutils
 # then enable email notifications in jenkins
 ```


#### Renew certificates for letsencrypt
- kill jenkins
- ./certbot-auto renew
- regenerate key with: https://github.com/pytorch/builder/blob/master/installjenkins.sh#L45-L49
- bash builder/runjenkins.sh

# How do the bots work?

The GitHub Pull Request builder Jenkins plugin comes with a bot
that can listen for comments on PRs and take actions accordingly.
The supported commands are:

* "@pytorchbot ok to test" to accept this pull request for testing
* "@pytorchbot test this please" for a one time test run
* "@pytorchbot add to whitelist" to add the author to the whitelist
* "@pytorchbot retest this please" to start a new build (if the build failed)

You have to be an 'admin' of the particular Jenkins project in order to
issue these commands.  Go to the 'configure' page of the project in
question and search for "Admin list" (under "GitHub Pull Request
Builder") and add your GitHub username.  By the way, you can see the
list of users who are already whitelisted by clicking the "Advanced..."
button.

# Testing community repos
First, build a docker image in the main pytorch repo, with the desired version:
```
cd pytorch/pytorch
git checkout v0.3.0
sudo docker build -t pytorch-v0.3.0 .
```

Next, run the docker
```
cd pytorch/builder/test_community_repos
sudo nvidia-docker run -it --rm -v $(pwd):/remote pytorch-v0.3.0:latest
```

Inside the docker,
```
cd /remote/
./run_all.sh
```

