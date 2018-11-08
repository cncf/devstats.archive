#!/bin/bash
if [ -z "$PG_HOST" ]
then
  PG_HOST=127.0.0.1
fi

if [ -z "$PG_PORT" ]
then
  PG_PORT=5432
fi
if [ -z "${PG_PASS}" ]
then
  echo "You need to set PG_PASS environment variable to run this script"
  exit 1
fi

if [ -z "$ONLY" ]
then
  host=`hostname`
  if [ $host = "teststats.cncf.io" ]
  then
    all=`cat ./devel/all_test_dbs.txt`
  else
    all=`cat ./devel/all_prod_dbs.txt`
  fi
  all="$all devstats"
else
  all=$ONLY
fi

if [ ! -z "$DROP" ]
then
  sudo -u postgres psql -h "$PG_HOST" -p "$PG_PORT" < ./util_sql/drop_ro_user.sql || exit 1
  for proj in $all
  do
    sudo -u postgres psql -h "$PG_HOST" -p "$PG_PORT" "$proj" < ./util_sql/drop_ro_user.sql || exit 2
  done
fi

if [ ! -z "$NOCREATE" ]
then
  echo "Skipping create"
  exit 0
fi

sudo -u postgres psql -h "$PG_HOST" -p "$PG_PORT" -c "create user ro_user with password '$PG_PASS'" || exit 3

for proj in $all
do
  ./devel/ro_user_grants.sh "$proj" || exit 4
done
echo 'OK'
