#!/bin/bash
echo 'Uses devstats runq command to connect to host postgres and display number of texts in the database'
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
if [ -z "$PG_DB" ]
then
  PG_DB=lfn
fi
docker run -e GHA2DB_SKIPTIME=1 -e GHA2DB_SKIPLOG=1 -e PG_PORT=65432 -e PG_HOST=`docker run -it devstats ip route show | awk '/default/ {print $3}'` -e PG_PASS="${PG_PASS}" -e PG_DB="${PG_DB}" -it devstats runq util_sql/num_texts.sql
