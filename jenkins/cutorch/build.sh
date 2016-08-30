# this will be running on the jenkins instance (ie not on nimbix instance)
#
# it is responsible for:
# - bringing up a nimbix instance / running a nimbix job
# - said nimbix job should then handle building torch, cutorch, running cutorch unit tests

# for now, this just says hello and stuff

env | grep GIT
env | grep ghprb
echo "h=$ghprbActualCommit&p=cutorch&b=$GIT_BRANCH&"
stdout_fname=$(mktemp)
curl -vs -d "h=$ghprbActualCommit&p=cutorch&b=$GIT_BRANCH&s=$shared_secret" "http://$WRAPPER_IP:3237/run" | tee  $stdout_fname

cat $stdout_fname | grep "ALL CHECKS PASSED"

