#!/bin/bash
# AURORA=1 - use Aurora DB
if [ -z "${PG_PASS}" ]
then
  echo "You need to set PG_PASS environment variable to run this script"
  exit 1
fi
if [ "${DEPLOY_FROM}" = "container" ]
then
  if [ -z "$AURORA" ]
  then
    host=`docker run devstats ip route show 2>/dev/null | awk '/default/ {print $3}'`
    docker run -e PG_PORT=65432 -e PG_HOST="${host}" -e PG_PASS="${PG_PASS}" devstats db.sh psql postgres -c 'select 1' 1>/dev/null 2>/dev/null && exit 0
  else
    docker run -e PG_ADMIN_USER=sa -e PG_PORT=5432 -e PG_HOST="dev-analytics-api-devstats-dev.cluster-czqvov18pw9a.us-west-2.rds.amazonaws.com" -e PG_PASS="${PG_PASS}" devstats db.sh psql postgres -c 'select 1' 1>/dev/null 2>/dev/null && exit 0
  fi
else
  if [ -z "$AURORA" ]
  then
    PG_PORT=65432 db.sh psql postgres -c 'select 1' 1>/dev/null 2>/dev/null && exit 0
  else
    PG_ADMIN_USER=sa PG_HOST="dev-analytics-api-devstats-dev.cluster-czqvov18pw9a.us-west-2.rds.amazonaws.com" db.sh psql postgres -c 'select 1' 1>/dev/null 2>/dev/null && exit 0
  fi
fi
while true
do
  r=0
  if [ "${DEPLOY_FROM}" = "container" ]
  then
    if [ -z "$AURORA" ]
    then
      host=`docker run devstats ip route show 2>/dev/null | awk '/default/ {print $3}'`
      docker run -e PG_PORT=65432 -e PG_HOST="${host}" -e PG_PASS="${PG_PASS}" devstats db.sh psql postgres -c 'select 1' 1>/dev/null 2>/dev/null
      r=$?
    else
      docker run -e PG_ADMIN_USER=sa -e PG_PORT=5432 -e PG_HOST="dev-analytics-api-devstats-dev.cluster-czqvov18pw9a.us-west-2.rds.amazonaws.com" -e PG_PASS="${PG_PASS}" devstats db.sh psql postgres -c 'select 1' 1>/dev/null 2>/dev/null
      r=$?
    fi
  else
    if [ -z "$AURORA" ]
    then
      PG_PORT=65432 db.sh psql postgres -c 'select 1' 1>/dev/null 2>/dev/null
      r=$?
    else
      PG_ADMIN_USER=sa PG_HOST="dev-analytics-api-devstats-dev.cluster-czqvov18pw9a.us-west-2.rds.amazonaws.com" db.sh psql postgres -c 'select 1' 1>/dev/null 2>/dev/null
      r=$?
    fi
  fi
  if [ ! "$r" = "0" ]
  then
    echo "Postgres not ready: $r"
    sleep 1
  else
    break
  fi
done
echo "Was waiting for the postgres, now ready"
