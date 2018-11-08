#!/bin/bash
echo 'Uses devstats runq command to connect to host postgres and display number of texts in the database'
if [ -z "$PG_PASS" ]
then
  echo "$0: you need to set PG_PASS=... environment variable"
  exit 1
fi
if [ -z "$PG_DB" ]
then
  PG_DB=allprj
fi
docker run -e PG_HOST=`docker run -it devstats ip route show | awk '/default/ {print $3}'` -e PG_PASS="${PG_PASS}" -e PG_DB="${PG_DB}" -it devstats runq util_sql/num_texts.sql
