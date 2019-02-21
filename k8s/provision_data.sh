#!/bin/bash
if [ -z "${AWS_PROFILE}" ]
then
  echo "$0: you need to set AWS_PROFILE=... to run this script"
  exit 1
fi
if [ -z "${DOCKER_USER}" ]
then
  echo "$0: you need to set docker user via DOCKER_USER=username"
  exit 2
fi
if ( [ -z "${GHA2DB_GITHUB_OAUTH}" ] && [ -z "${GHA2DB_GHAPISKIP}" ] )
then
  echo "$0: warning no GitHub API key provided via GHA2DB_GITHUB_OAUTH=..., falling back to public API (very limited)"
  echo "You can also skip GitHub API processing by setting GHA2DB_GHAPISKIP=1"
  GHA2DB_GITHUB_OAUTH="-"
fi

# XXX: sysctl
# ./cron/sysctl_config.sh
# XXX: need to configure persistent storage for git data (should check if that exists - if not it should create PV)
# ./k8s/configure_pv.sh 
# docker run --mount src="/data/devstats",target="/root",type=bind -e AURORA=1 -e INIT=1 -e SKIPTEMP=1 -e NOLOCK=1 -e NOBACKUP=1 -e SKIPADDALL=1 -e UDROP="${UDROP}" -e LDROP="${LDROP}" -e DBDEBUG="${DBDEBUG}" -e ONLY="${ONLY}" -e GHA2DB_GITHUB_OAUTH="${GHA2DB_GITHUB_OAUTH}" -e GHA2DB_GHAPISKIP="${GHA2DB_GHAPISKIP}" -e PG_PORT=5432 -e TEST_SERVER=1 -e ES_PORT=19200 -e ES_HOST="${host}" -e PG_HOST="dev-analytics-api-devstats-dev.cluster-czqvov18pw9a.us-west-2.rds.amazonaws.com" -e PG_PASS="${PG_PASS}" -e PG_PASS_RO="${PG_PASS_RO}" -e PG_PASS_TEAM="${PG_PASS_TEAM}" --env-file <(env | grep GHA2DB) devstats ./docker/docker_deploy_all.sh

# XXX: Pass PVC somehow (must be mountded in ~/devstats_repos/)
cmd="kubectl run -i --tty devstats-provision --restart=Never --rm --image=\"${DOCKER_USER}/devstats\" --env=\"INIT=${INIT}\" --env=\"GET=${GET}\" --env=\"SKIPVARS=${SKIPVARS}\" --env=\"SKIPTEMP=1\" --env=\"NOLOCK=1\" --env=\"NOBACKUP=1\" --env=\"SKIPADDALL=1\" --env=\"UDROP=${UDROP}\" --env=\"NOCREATE=${NOCREATE}\" --env=\"LDROP=${LDROP}\" --env=\"DBDEBUG=${DBDEBUG}\" --env=\"ONLY=${ONLY}\" --env=\"TEST_SERVER=1\" --env=\"GETREPOS=${GETREPOS}\""
for f in `env | sort | grep GHA2DB`
do
  cmd="${cmd} --env=\"$f\""
done
for f in `env | sort | grep PG_`
do
  cmd="${cmd} --env=\"$f\""
done
for f in `env | sort | grep ES_`
do
  cmd="${cmd} --env=\"$f\""
done
cmd="${cmd} --command ./k8s/deploy_all.sh"
echo $cmd
eval $cmd
