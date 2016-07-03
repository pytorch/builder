# jenkins configuration

This is using manual configuration.  Ideally, we'd have 'configuration as code', and use eg JenkinsJobBuilder, but jenkins job builder has a certain management overhead, whereas using jenkins interface directly is relativley quick, so since I have access ot the interface, going the interface route for now.  We probably should ocnisder going jjb route sooner or later though.  Maybe.

## DONE: Jenkins-side configuration 1: create build job

So, what I did is, documenting as I go along:
- ssh into hte instance
- cat torchunit/config.yaml
- this gives me hte jenkins password
- open my web browser, connect using https, to the jenkins instance url, with port 8443
- log in with user jenkins, and password from above
- click on 'new item' to create a new job
- job details:
```
Project name: cutorch
Discard old builds: yes
    Days to keep builds: 3
    Max # builds to keep: 10
Source code management: Git
    Repository url: https://github.com/torch/cutorch
Branches to build: change to being empty
    Build periodically: yes
        Schedule: 0 */3 * * *
Build: 'add build step', 'execute shell'
    Command:
      echo test
      env | grep GIT
      git log -n 3 --oneline
      git status
      if [ -d torchunit ]; then { rm -Rf torchunit; } fi
      git clone https://github.com/hughperkins/torchunit
      cd torchunit
      bash jenkins/cutorch/build.sh
click 'save'
click 'build now' to test
```

## TODO: github configuration 1: set up autobuild for commits to torch/cutorch repo

- open browser, navigate to https://github.com/torch/cutorch/settings
- click on 'webhooks & services'
- 'add service', 'jenkins (git plugin)'
- jenkins url will looks something like: 'https://54.1.2.3.4:8443/'

## TODO: github configuration 2: create account for pull request builder plugin

- create a new user, eg `torch-bot` (this needs an appropriate email account I think? though could create a new gmail account too perhaps?)
- grant the user push/pull access to the torch/cutorch repo
- go to https://github.com/settings/tokens
- click on 'generate new token'
- click on 'repo', and create the token
- => this token grants access to modify the code on torch/cutorch' repo, so keep it safe... <=
- note it down somewhere, for the 'jenkins configuratoin 3' sectipn

## DONE: jenkins configuration 2: install github pull request builder plugin

- go to jenkins home page
- click on 'manage jenkins', 'manage plugins'
- click on 'available' tab
- in 'filter' put 'github pull'
- next to 'github pull request builder', tick the box
- click 'install without restart'

## TODO: jenkins configuration 3: configure github pull request builder plugin

- go to jenkins home page
- go to 'manage jenkins', 'congigure system'
- scroll down to setion 'github pull request builder'
- in 'admin list', put:
    soumith
    szagoruyko
    hughperkins
(and anyone else who should be admin)
- next to 'credentials' click 'add', then 'jenkins'
   - kind: 'secret text'
   - secret: the api token from 'github configuration 2' section above
   - id: jenkins-bot-github-token
   - description: jenkins-bot-github-token
   - click on 'add'
- click on 'basic connection to github'
   - click on 'connect to api'
   - verify passes ok
- click 'test permissions to a repository'
   - put 'repository owner/name': 'torch/cutorch'
   - click 'check repo permissoins'
   - check passes ok
- right at the bottom of the page, click on 'save'

## TODO: jenkins configuration 4: create job for pull request builder plugin

- todo, but will be essentially the same job as created in first section (just the branch specs etc might be slightly different?)

