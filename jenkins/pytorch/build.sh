# this will be running on the jenkins instance 
#
# it is responsible for:
# checking BUILDER_TYPE environment var.
# if BUILDER_TYPE == NIMBIX
#   - bringing up a nimbix instance / running a nimbix job
#   - said nimbix job should then handle building pytorch unit tests
# else if BUILDER_TYPE == LOCAL (or doesn't exist)
#   current box should handle building pytorch unit tests

env | grep GIT
env | grep ghprb
env | grep jenkins_python_version

if [ -z "$github_token" ]; then
    echo "could not find env variable github_token, exiting"
    exit 1
fi

COMMIT_TO_TEST=""
if [ -z "$ghprbActualCommit" ]; then
    # not building in the ghprb regime, probably building master
    COMMIT_TO_TEST=$GIT_COMMIT
else 
    # building a pull request
    COMMIT_TO_TEST=$ghprbActualCommit
fi

if [ -z "$jenkins_python_version" ]; then
    echo "jenkins_python_version is not defined. define it to 2 or 3"
    exit 1
fi

BUILDER=${BUILDER_TYPE:-LOCAL}

if [ "$BUILDER" == "NIMBIX"]; then
    echo "h=$COMMIT_TO_TEST&p=pytorch&b=$GIT_BRANCH&"
    stdout_fname=$(mktemp)
    curl -vs -d "h=$COMMIT_TO_TEST&p=pytorch&b=$GIT_BRANCH&s=$shared_secret&g=$github_token&py=$jenkins_python_version" "http://localhost:3237/run" | tee  $stdout_fname

    cat $stdout_fname | grep "ALL CHECKS PASSED"
elif [ "$BUILDER" == "LOCAL"]; then
    cd /tmp
    rm -rf /tmp/builder
    if ! which git
    then
	sudo apt-get install -y git
    fi
    git clone https://pytorchbot:$github_token@github.com/pytorch/builder --quiet
    cd builder
    stdout_fname=$(mktemp)
    bash nimbix-bootstrap.sh pytorch $COMMIT_TO_TEST $GIT_BRANCH \
	$github_token $jenkins_python_version | tee  $stdout_fname
    cat $stdout_fname | grep "ALL CHECKS PASSED"
else
    echo "unknown BUILDER = $BUILDER , exiting"
    exit 1
fi
