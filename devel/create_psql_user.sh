#!/bin/bash
if [ -z "${PG_PASS}" ]
then
  echo "$0: You need to set PG_PASS environment variable to run this script"
  exit 1
fi

if [ -z "$1" ]
then
  echo "$0: user name required"
  exit 1
fi

. ./devel/all_dbs.sh || exit 2
if [ -z "$ONLY" ]
then
  all="$all devstats"
fi

cp ./util_sql/drop_psql_user.sql /tmp/drop_user.sql || exit 1
FROM="{{user}}" TO="$1" MODE=ss ./replacer /tmp/drop_user.sql || exit 1

if [ ! -z "$DROP" ]
then
  echo "Drop from public"
  ./devel/db.sh psql < /tmp/drop_user.sql || exit 1
  for db in $all
  do
    echo "Drop from $db"
    ./devel/db.sh psql "$db" < /tmp/drop_user.sql || exit 1
  done
fi

if [ ! -z "$NOCREATE" ]
then
  echo "Skipping create"
  exit 0
fi

echo "Create role"
./devel/db.sh psql postgres -c "create user \"$1\" with password '$PG_PASS'" || exit 1

for db in $all
do
  echo "Grants $db"
  ./devel/psql_user_grants.sh "$1" "$db" || exit 2
done
echo 'OK'
