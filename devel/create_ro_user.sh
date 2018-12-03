#!/bin/bash
if [ -z "${PG_PASS}" ]
then
  echo "You need to set PG_PASS environment variable to run this script"
  exit 1
fi

. ./devel/all_dbs.sh || exit 2

if [ ! -z "$DROP" ]
then
  ./devel/db.sh psql < ./util_sql/drop_ro_user.sql || exit 1
  for proj in $all
  do
    ./devel/db.sh psql "$proj" < ./util_sql/drop_ro_user.sql || exit 2
  done
fi

if [ ! -z "$NOCREATE" ]
then
  echo "Skipping create"
  exit 0
fi

./devel/db.sh psql postgres -c "create user ro_user with password '$PG_PASS'" || exit 3

for proj in $all
do
  ./devel/ro_user_grants.sh "$proj" || exit 4
done
echo 'OK'
