#!/bin/bash
# AURORA=1 - use Aurora DB
if ( [ -z "$PG_PASS" ] || [ -z "$PG_PASS_RO" ] || [ -z "$PG_PASS_TEAM" ] )
then
  echo "$0: you need to set PG_PASS=... PG_PASS_RO=... PG_PASS_TEAM=... environment variables"
  exit 1
fi
if ( [ -z "${GHA2DB_GITHUB_OAUTH}" ] && [ -z "${GHA2DB_GHAPISKIP}" ] )
then
  echo "$0: warning no GitHub API key provided via GHA2DB_GITHUB_OAUTH=..., falling back to public API (very limited)"
  echo "You can also skip GitHub API processing by setting GHA2DB_GHAPISKIP=1"
  export GHA2DB_GITHUB_OAUTH="-"
fi
./cron/sysctl_config.sh
if [ -z "$AURORA" ]
then
  INIT=1 SKIPTEMP=1 NOLOCK=1 SKIPADDALL=1 NOBACKUP=1 ES_HOST="127.0.0.1" PG_HOST=127.0.0.1 PG_PORT=65432 ./docker/docker_deploy_all.sh
else
  INIT=1 SKIPTEMP=1 NOLOCK=1 SKIPADDALL=1 NOBACKUP=1 ES_HOST="127.0.0.1" PG_HOST="dev-analytics-api-devstats-dev.cluster-czqvov18pw9a.us-west-2.rds.amazonaws.com" PG_PORT=5432 ./docker/docker_deploy_all.sh
fi
