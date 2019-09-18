#!/bin/bash
if [ -z "${PG_PASS}" ]
then
  echo "You need to set PG_PASS environment variable to run this script"
  exit 1
fi
. ./devel/all_dbs.sh || exit 2
for db in $all
do
  ./devel/ro_user_grants.sh "$db" || exit 3
  ./devel/psql_user_grants.sh devstats_team "$db" || exit 4
done
echo 'OK'

