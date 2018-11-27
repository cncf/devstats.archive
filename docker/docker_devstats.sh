#!/bin/bash
echo 'Uses devstats to sync projects, supposed to run hourly'
if [ -z "$PG_PASS" ]
then
  if [ -z "$INTERACTIVE" ]
  then
    echo "$0: you need to set PG_PASS=... environment variable"
    exit 1
  else
    echo -n 'Postgres pwd: '
    read -s PG_PASS
    echo ''
  fi
fi
if ( [ -z "${GHA2DB_GITHUB_OAUTH}" ] && [ -z "${GHA2DB_GHAPISKIP}" ] )
then
  echo "$0: warning no GitHub API key provided via GHA2DB_GITHUB_OAUTH=..., falling back to public API (very limited)"
  echo "You can also skip GitHub API processing by setting GHA2DB_GHAPISKIP=1"
  GHA2DB_GITHUB_OAUTH="-"
fi
PG_HOST=`docker run -it devstats ip route show | awk '/default/ {print $3}'`
./cron/net_tcp_config.sh
# -e GHA2DB_DEBUG=2 -e GHA2DB_CMDDEBUG=2 -e GHA2DB_QOUT=1
docker run -e GHA2DB_ES_URL="http://${PG_HOST}:19200" -e GHA2DB_USE_ES=1 -e GHA2DB_USE_ES_RAW=1 -e GHA2DB_GITHUB_OAUTH="${GHA2DB_GITHUB_OAUTH}" -e GHA2DB_GHAPISKIP="${GHA2DB_GHAPISKIP}" -e GHA2DB_PROJECTS_YAML="docker/docker_projects.yaml" -e GHA2DB_GHAPISKIP=1 -e PG_PORT=65432 -e PG_HOST="${PG_HOST}" -e PG_PASS="${PG_PASS}" -it devstats devstats
