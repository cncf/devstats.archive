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
docker run -e GHA2DB_PROJECTS_YAML="docker/docker_projects.yaml" -e GHA2DB_GHAPISKIP=1 -e PG_PORT=65432 -e PG_HOST=`docker run -it devstats ip route show | awk '/default/ {print $3}'` -e PG_PASS="${PG_PASS}" -it devstats devstats
