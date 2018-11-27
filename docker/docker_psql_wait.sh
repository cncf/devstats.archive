#!/bin/bash
if [ -z "${PG_PASS}" ]
then
  echo "You need to set PG_PASS environment variable to run this script"
  exit 1
fi
host=`docker run -it devstats ip route show 2>/dev/null | awk '/default/ {print $3}'`
docker run -e PG_PORT=65432 -e PG_HOST="${host}" -e PG_PASS="${PG_PASS}" -it devstats db.sh psql -c 'select 1' 1>/dev/null 2>/dev/null && exit 0
while true
do
  host=`docker run -it devstats ip route show 2>/dev/null | awk '/default/ {print $3}'`
  docker run -e PG_PORT=65432 -e PG_HOST="${host}" -e PG_PASS="${PG_PASS}" -it devstats db.sh psql -c 'select 1' 1>/dev/null 2>/dev/null
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
