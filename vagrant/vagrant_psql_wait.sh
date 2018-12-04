#!/bin/bash
# AURORA=1 - use Aurora DB
if [ -z "${PG_PASS}" ]
then
  echo "You need to set PG_PASS environment variable to run this script"
  exit 1
fi
docker run -e PG_USER="${PG_USER}" -e PG_PORT="${PG_PORT}" -e PG_HOST="${PG_HOST}" -e PG_PASS="${PG_PASS}" -it devstats db.sh psql postgres -c 'select 1' 1>/dev/null 2>/dev/null && exit 0
while true
do
  docker run -e PG_USER="${PG_USER}" -e PG_PORT="${PG_PORT}" -e PG_HOST="${PG_HOST}" -e PG_PASS="${PG_PASS}" -it devstats db.sh psql postgres -c 'select 1' 1>/dev/null 2>/dev/null
  r=$?
  if [ ! "$r" = "0" ]
  then
    echo "Postgres not ready: $r"
    sleep 1
  else
    break
  fi
done
echo "Was waiting for the postgres, now ready"
