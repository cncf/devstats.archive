#!/bin/bash
# AURORA=1 - use Aurora DB
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
export TEST_SERVER=1
export LIST_FN_PREFIX="docker/all_"
. ./devel/all_dbs.sh || exit 2
for db in $all
do
  echo "Database: $db"
  docker run --network=lfda_default -e GHA2DB_SKIPTIME=1 -e GHA2DB_SKIPLOG=1 -e PG_USER="${PG_USER}" -e PG_PORT="${PG_PORT}" -e PG_HOST="${PG_HOST}" -e PG_PASS="${PG_PASS}" -e PG_DB="${db}" --env-file <(env | grep GHA2DB) devstats runq util_sql/num_texts.sql || exit 3
done
user=gha_admin
if [ ! -z "${PG_USER}" ]
then
  user="${PG_USER}"
fi
docker run --network=lfda_default -e PG_USER="${user}" -e PG_PORT="${PG_PORT}" -e PG_HOST="${PG_HOST}" -e PG_PASS="${PG_PASS}" devstats db.sh psql lfn -c 'select * from sannotations_shared limit 10' || exit 4
