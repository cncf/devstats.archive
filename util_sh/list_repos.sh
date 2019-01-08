#!/bin/bash
if [ -z "${PG_PASS}" ]
then
  echo "You need to set PG_PASS environment variable to run this script"
  exit 1
fi
. ./devel/all_dbs.sh || exit 2
> list_repos.csv
for db in $all
do
  PG_DB="$db" GHA2DB_LOCAL=1 GHA2DB_CSVOUT="/tmp/temp.csv" ./runq ./util_sql/list_repos.sql {{project}} "$db"
  cat /tmp/temp.csv >> list_repos.csv
done
