# this will be running on the jenkins instance (ie not on nimbix instance)
#
# it is responsible for:
# - bringing up a nimbix instance / running a nimbix job
# - said nimbix job should then handle building pytorch unit tests

# for now, this just says hello and stuff

env | grep GIT
env | grep ghprb
env | grep jenkins_python_version

COMMIT_TO_TEST=""
if [ -z "$ghprbActualCommit" ]; then
    # not building in the ghprb regime, probably building master
    COMMIT_TO_TEST=$GIT_COMMIT
else 
    # building a pull request
    COMMIT_TO_TEST=$ghprbActualCommit
fi

python_version=""
if [ -z "$jenkins_python_version" ]; then
    python_version=3
else
    python_version=2
fi

echo "h=$COMMIT_TO_TEST&p=pytorch&b=$GIT_BRANCH&"
stdout_fname=$(mktemp)
curl -vs -d "h=$COMMIT_TO_TEST&p=pytorch&b=$GIT_BRANCH&s=$shared_secret&g=$github_token&py=$python_version" "http://localhost:3237/run" | tee  $stdout_fname

cat $stdout_fname | grep "ALL CHECKS PASSED"

