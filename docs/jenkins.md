# jenkins configuration

## jenkins configuration 1: install github pull request builder plugin

- go to jenkins home page
- click on 'manage jenkins', 'manage plugins'
- click on 'available' tab
- in 'filter' put 'github pull'
- next to 'github pull request builder', tick the box
- click 'install without restart'

## jenkins configuration 2: configure github pull request builder plugin

- go to jenkins home page
- go to 'manage jenkins', 'congigure system'
- scroll down to entry 'github pull request builder'
- in shared secret, put some shared secret and note it down (might as well be same as one used for comms with nimbix wrapper, I think?)
- next to 'credentials' click 'add', then 'jenkins'
   - kind: 'secret text'
   - secret: [pytorchbot github api token]
   - id: jenkins-bot-github-token
   - description: jenkins-bot-github-token
   - click on 'add'
- fill in description 'jenkins-bot-github-token'
- click button 'test credentials'
- click on 'basic connection to github'
   - click on 'connect to api'
   - verify passes ok
- click 'test permissions to a repository'
   - put 'repository owner/name': 'pytorch/pytorch'
   - click 'check repo permissions'
   - check passes ok
- unclick 'automanage webhooks'
- in 'admin list', put:
    soumith
	colesbury
	apaszke
	szagoruyko
(and anyone else who should be admin)
- right at the bottom of the page, click on 'save'

## jenkins configuration 3: create job for pull request builder plugin

- click on 'new item' to create a new job
- job details:
```
Project name: pytorch
Project type: freestyle project
Discard old builds: yes
    Days to keep builds: 10
    Max # builds to keep: 20
Github Project:
   Project URL: https://github.com/pytorch/pytorch
Source code management: Git
    Repository url: https://github.com/pytorch/pytorch
	Credentials: add pytorchbot and it's github token as username/pass
    click 'advanced'
        refspec: +refs/pull/*:refs/remotes/origin/pr/*
Branches to build: ${sha1}
In 'build triggers', tick 'github pull request builder'
   - fill in admin list
Build: 'add build step', 'execute shell'
    Command:
      echo test
      env | grep GIT
      git log -n 3 --oneline
      git status
      if [ -d builder ]; then { rm -Rf builder; } fi
      git clone git@github.com:pytorch/builder.git
      cd builder
      bash jenkins/pytorch/build.sh
click 'save'
```

