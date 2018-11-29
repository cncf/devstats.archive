#!/bin/bash
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
./cron/sysctl_config.sh
./docker/docker_make_mount_dirs.sh
host=`docker run -it devstats ip route show 2>/dev/null | awk '/default/ {print $3}'`
docker run --mount src="/data/devstats",target="/root",type=bind -e INIT=1 -e SKIPTEMP=1 -e NOLOCK=1 -e NOBACKUP=1 -e SKIPADDALL=1 -e ONLY="${ONLY}" -e GHA2DB_GITHUB_OAUTH="${GHA2DB_GITHUB_OAUTH}" -e GHA2DB_GHAPISKIP="${GHA2DB_GHAPISKIP}" -e PG_PORT=65432 -e TEST_SERVER=1 -e PG_HOST="${host}" -e PG_PASS="${PG_PASS}" -e PG_PASS_RO="${PG_PASS_RO}" -e PG_PASS_TEAM="${PG_PASS_TEAM}" --env-file <(env | grep GHA2DB) -it devstats ./docker/docker_deploy_all.sh
