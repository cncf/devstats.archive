#!/bin/bash
# AURORA=1 - use Aurora DB
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
./cron/sysctl_config.sh
./docker/docker_make_mount_dirs.sh
docker run --network=lfda_default --mount src="/data/devstats",target="/root",type=bind -e ONLY="${ONLY}" -e GHA2DB_ES_URL="http://${ES_HOST}:${ES_PORT}" -e GHA2DB_USE_ES=1 -e GHA2DB_USE_ES_RAW=1 -e GHA2DB_GITHUB_OAUTH="${GHA2DB_GITHUB_OAUTH}" -e GHA2DB_GHAPISKIP="${GHA2DB_GHAPISKIP}" -e GHA2DB_PROJECTS_YAML="docker/docker_projects.yaml" -e PG_PORT="${PG_PORT}" -e PG_HOST="${PG_HOST}" -e PG_PASS="${PG_PASS}" -e PG_USER="${PG_USER}" --env-file <(env | grep GHA2DB) devstats devstats
