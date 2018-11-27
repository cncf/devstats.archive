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
./cron/net_tcp_config.sh
docker run -e INIT=1 -e SKIPTEMP=1 -e NOLOCK=1 -e NOBACKUP=1 -e SKIPADDALL=1 -e GHA2DB_GITHUB_OAUTH="${GHA2DB_GITHUB_OAUTH}" -e GHA2DB_GHAPISKIP="${GHA2DB_GHAPISKIP}" -e PG_PORT=65432 -e PG_HOST=`docker run -it devstats ip route show | awk '/default/ {print $3}'` -e PG_PASS="${PG_PASS}" -e PG_PASS_RO="${PG_PASS_RO}" -e PG_PASS_TEAM="${PG_PASS_TEAM}" -it devstats ./docker/docker_deploy_all.sh
