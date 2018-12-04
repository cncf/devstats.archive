#!/bin/bash
# AURORA=1 - use Aurora DB
echo 'Uses devstats runq command to connect to host postgres and display top 10 log messages'
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
docker run  --network=lfda_default -e GHA2DB_SKIPTIME=1 -e GHA2DB_SKIPLOG=1 -e PG_USER="${PG_USER}" -e PG_PORT="${PG_PORT}" -e PG_HOST="${PG_HOST}" -e PG_PASS="${PG_PASS}" -e PG_DB=devstats --env-file <(env | grep GHA2DB) devstats runq util_sql/recent_log.sql '{{lim}}' 10
