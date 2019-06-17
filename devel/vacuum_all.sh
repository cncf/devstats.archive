#!/bin/bash
if [ -z "${PG_PASS}" ]
then
  echo "You need to set PG_PASS environment variable to run this script"
  exit 1
fi
PG_USER=postgres
dbs=`./devel/db.sh psql -tAc "select datname from pg_database"`
for db in $dbs
do
  echo "${db}..."
  ./devel/db.sh psql "$db" -c vacuum
done
