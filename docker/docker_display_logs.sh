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
if [ "${DEPLOY_FROM}" = "container" ]
then
  if [ -z "$AURORA" ]
  then
    host=`docker run -it devstats ip route show | awk '/default/ {print $3}'`
    docker run -e GHA2DB_SKIPTIME=1 -e GHA2DB_SKIPLOG=1 -e PG_PORT=65432 -e PG_HOST="${host}" -e PG_PASS="${PG_PASS}" -e PG_DB=devstats --env-file <(env | grep GHA2DB) -it devstats runq util_sql/recent_log.sql '{{lim}}' 10
  else
    docker run -e GHA2DB_SKIPTIME=1 -e GHA2DB_SKIPLOG=1 -e PG_PORT=5432 -e PG_HOST="dev-analytics-api-devstats-dev.cluster-czqvov18pw9a.us-west-2.rds.amazonaws.com" -e PG_PASS="${PG_PASS}" -e PG_DB=devstats --env-file <(env | grep GHA2DB) -it devstats runq util_sql/recent_log.sql '{{lim}}' 10
  fi
else
  if [ -z "$AURORA" ]
  then
    GHA2DB_SKIPTIME=1 GHA2DB_SKIPLOG=1 PG_PORT=65432 PG_DB=devstats runq util_sql/recent_log.sql '{{lim}}' 10
  else
    GHA2DB_SKIPTIME=1 GHA2DB_SKIPLOG=1 PG_HOST="dev-analytics-api-devstats-dev.cluster-czqvov18pw9a.us-west-2.rds.amazonaws.com" PG_DB=devstats runq util_sql/recent_log.sql '{{lim}}' 10
  fi
fi
