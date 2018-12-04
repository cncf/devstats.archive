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
  GHA2DB_GITHUB_OAUTH="-"
fi
if [ -z "${PG_PORT}" ]
then
  PG_PORT=5432
fi
./cron/sysctl_config.sh
./docker/docker_make_mount_dirs.sh
docker run --mount src="/data/devstats",target="/root",type=bind -e INIT=1 -e SKIPTEMP=1 -e NOLOCK=1 -e NOBACKUP=1 -e SKIPADDALL=1 -e UDROP="${UDROP}" -e LDROP="${LDROP}" -e DBDEBUG="${DBDEBUG}" -e ONLY="${ONLY}" -e GHA2DB_GITHUB_OAUTH="${GHA2DB_GITHUB_OAUTH}" -e GHA2DB_GHAPISKIP="${GHA2DB_GHAPISKIP}" -e PG_USER="${PG_USER}" -e PG_PORT="${PG_PORT}" -e TEST_SERVER=1 -e ES_HOST="localhost" -e PG_HOST="${PG_HOST}" -e PG_PASS="${PG_PASS}" -e PG_PASS_RO="${PG_PASS_RO}" -e PG_PASS_TEAM="${PG_PASS_TEAM}" --env-file <(env | grep GHA2DB) devstats ./docker/docker_deploy_all.sh
