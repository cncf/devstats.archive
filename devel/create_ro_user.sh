#!/bin/bash
if [ -z "${PG_PASS}" ]
then
  echo "You need to set PG_PASS environment variable to run this script"
  exit 1
fi

. ./devel/all_dbs.sh || exit 2
if [ -z "$ONLY" ]
then
  all="$all devstats"
fi

if [ -z "$PG_ADMIN_USER" ]
then
  admin=postgres
else
  admin="${PG_ADMIN_USER}"
fi

if [ ! -z "$DROP" ]
then
  cp ./util_sql/drop_ro_user.sql /tmp/drop_ro_user.sql || exit 3
  FROM="{{admin_user}}" TO="${admin}" MODE=ss replacer /tmp/drop_ro_user.sql || exit 4
  ./devel/db.sh psql postgres < /tmp/drop_ro_user.sql || exit 5
  for proj in $all
  do
    ./devel/db.sh psql "$proj" < /tmp/drop_ro_user.sql || exit 6
  done
  rm -f /tmp/drop_ro_user.sql
fi

if [ ! -z "$NOCREATE" ]
then
  echo "Skipping create"
  exit 0
fi

./devel/db.sh psql postgres -c "create user ro_user with password '$PG_PASS'" || exit 7

for proj in $all
do
  ./devel/ro_user_grants.sh "$proj" || exit 8
done
echo 'OK'
