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
host=`docker run -it devstats ip route show 2>/dev/null | awk '/default/ {print $3}'`
. ./devel/all_dbs.sh || exit 2
for db in $all
do
  echo "Database: $db"
  docker run -e GHA2DB_SKIPTIME=1 -e GHA2DB_SKIPLOG=1 -e PG_PORT=65432 -e PG_HOST="${host}" -e PG_PASS="${PG_PASS}" -e PG_DB="${db}" --env-file <(env | grep GHA2DB) -it devstats runq util_sql/num_texts.sql || exit 3
done
docker run -e PG_PORT=65432 -e PG_HOST="${host}" -e PG_PASS="${PG_PASS}" -it devstats db.sh psql lfn -c 'select * from sannotations_shared limit 10' || exit 4
