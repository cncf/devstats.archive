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
if [ "${DEPLOY_FROM}" = "container" ]
then
  host=`docker run -it devstats ip route show | awk '/default/ {print $3}'`
  if [ -z "$AURORA" ]
  then
    docker run --mount src="/data/devstats",target="/root",type=bind -e ONLY="${ONLY}" -e GHA2DB_ES_URL="http://${host}:19200" -e GHA2DB_USE_ES=1 -e GHA2DB_USE_ES_RAW=1 -e GHA2DB_GITHUB_OAUTH="${GHA2DB_GITHUB_OAUTH}" -e GHA2DB_GHAPISKIP="${GHA2DB_GHAPISKIP}" -e GHA2DB_PROJECTS_YAML="docker/docker_projects.yaml" -e PG_PORT=65432 -e PG_HOST="${host}" -e PG_PASS="${PG_PASS}" --env-file <(env | grep GHA2DB) -it devstats devstats
  else
    docker run --mount src="/data/devstats",target="/root",type=bind -e ONLY="${ONLY}" -e GHA2DB_ES_URL="http://${host}:19200" -e GHA2DB_USE_ES=1 -e GHA2DB_USE_ES_RAW=1 -e GHA2DB_GITHUB_OAUTH="${GHA2DB_GITHUB_OAUTH}" -e GHA2DB_GHAPISKIP="${GHA2DB_GHAPISKIP}" -e GHA2DB_PROJECTS_YAML="docker/docker_projects.yaml" -e PG_PORT=5432 -e PG_HOST="dev-analytics-api-devstats-dev.cluster-czqvov18pw9a.us-west-2.rds.amazonaws.com" -e PG_PASS="${PG_PASS}" --env-file <(env | grep GHA2DB) -it devstats devstats
  fi
else
  if [ -z "$AURORA" ]
  then
    GHA2DB_LOCAL=1 GHA2DB_ES_URL="http://localhost:19200" GHA2DB_USE_ES=1 GHA2DB_USE_ES_RAW=1 GHA2DB_PROJECTS_YAML="docker/docker_projects.yaml" PG_PORT=65432 devstats
  else
    GHA2DB_LOCAL=1 GHA2DB_ES_URL="http://localhost:19200" GHA2DB_USE_ES=1 GHA2DB_USE_ES_RAW=1 GHA2DB_PROJECTS_YAML="docker/docker_projects.yaml" PG_HOST="dev-analytics-api-devstats-dev.cluster-czqvov18pw9a.us-west-2.rds.amazonaws.com" devstats
  fi
fi
