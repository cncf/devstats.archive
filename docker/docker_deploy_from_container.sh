#!/bin/bash
echo 'Uses devstats runq command to connect to host postgres and display number of texts in the database'
if ( [ -z "$PG_PASS" ] || [ -z "$PG_PASS_RO" ] || [ -z "$PG_PASS_TEAM" ] )
then
  echo "$0: you need to set PG_PASS=... PG_PASS_RO=... PG_PASS_TEAM=... environment variables"
  exit 1
fi
docker run -e INIT=1 -e GHA2DB_GHAPISKIP=1 -e SKIPTEMP=1 -e NOLOCK=1 -e PG_PORT=65432 -e PG_HOST=`docker run -it devstats ip route show | awk '/default/ {print $3}'` -e PG_PASS="${PG_PASS}" -e PG_PASS_RO="${PG_PASS_RO}" -e PG_PASS_TEAM="${PG_PASS_TEAM}" -it devstats ./docker/docker_deploy_all.sh
