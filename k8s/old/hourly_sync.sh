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
if  [ -z "$ONLY" ]
then
  echo "$0: warning ONLY=... not set, will sync all projects"
fi

echo "WARNING: this old deployment mode is not passing secrets and is not mounting volumes - avoid using it"
# ./cron/sysctl_config.sh

ts=`date +'%s%N'`
cmd='kubectl run --schedule="8 * * * *"'
cmd="${cmd} -i --tty \"devstats-${ts}\" --restart=Never --rm --image=\"${DOCKER_USER}/devstats-minimal\" --env=\"ONLY=${ONLY}\""
for f in `env | grep -E '(ES_|PG_|GHA2DB)'`
do
  cmd="${cmd} --env=\"$f\""
done
cmd="${cmd} --command devstats"
echo "${cmd}"
eval "${cmd}"
