#!/bin/bash
if [ -z "${PG_PASS}" ]
then
  echo "$0: You need to set PG_PASS environment variable to run this script"
  exit 1
fi

if [ -z "$1" ]
then
  echo "$0: user name required"
  exit 2
fi

. ./devel/all_dbs.sh || exit 3
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
  cp ./util_sql/drop_psql_user.sql /tmp/drop_user.sql || exit 4
  FROM="{{user}}" TO="$1" MODE=ss replacer /tmp/drop_user.sql || exit 5
  FROM="{{admin_user}}" TO="${admin}" MODE=ss replacer /tmp/drop_user.sql || exit 6
  echo "Drop from public"
  ./devel/db.sh psql postgres < /tmp/drop_user.sql || exit 7
  for db in $all
  do
    echo "Drop from $db"
    ./devel/db.sh psql "$db" < /tmp/drop_user.sql || exit 8
  done
  rm -f /tmp/drop_user.sql
fi

if [ ! -z "$NOCREATE" ]
then
  echo "Skipping create"
  exit 0
fi

echo "Create role"
./devel/db.sh psql postgres -c "create user \"$1\" with password '$PG_PASS'" || exit 9

for db in $all
do
  echo "Grants $db"
  ./devel/psql_user_grants.sh "$1" "$db" || exit 10
done
echo 'OK'
