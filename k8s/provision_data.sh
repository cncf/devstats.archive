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
if ( [ -z "$PROJ" ] || [ -z "$PROJDB" ] || [ -z "$PROJREPO" ] )
then
  echo "$0: You need to set PROJ, PROJDB, PROJREPO environment variables to run this script"
  exit 3
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
# XXX: Pass PVC somehow (must be mountded in ~/devstats_repos/)

ts=`date +'%s%N'`
cmd="kubectl run -i --tty \"devstats-provision-${ts}\" --restart=Never --rm --image=\"${DOCKER_USER}/devstats\" --env=\"PROJ=${PROJ}\" --env=\"PROJDB=${PROJDB}\" --env=\"PROJREPO=${PROJREPO}\" --env=\"INIT=${INIT}\" --env=\"GET=${GET}\" --env=\"SKIPVARS=${SKIPVARS}\" --env=\"SKIPTEMP=1\" --env=\"NOLOCK=1\" --env=\"NOBACKUP=1\" --env=\"SKIPADDALL=1\" --env=\"UDROP=${UDROP}\" --env=\"NOCREATE=${NOCREATE}\" --env=\"LDROP=${LDROP}\" --env=\"DBDEBUG=${DBDEBUG}\" --env=\"ONLY=${ONLY}\" --env=\"TEST_SERVER=1\" --env=\"GETREPOS=${GETREPOS}\""
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
