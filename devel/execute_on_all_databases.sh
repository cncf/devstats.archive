#!/bin/bash
if [ -z "$PG_HOST" ]
then
  PG_HOST=127.0.0.1
fi

if [ -z "$PG_PORT" ]
then
  PG_PORT=5432
fi
if [ -z "$1" ]
then
  echo "$0: at least one SQL script required"
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
else
  all=$ONLY
fi
for db in $all
do
  for sql in $*
  do
    echo "Execute script '$sql' on '$db' database"
    sudo -u postgres psql -h "$PG_HOST" -p "$PG_PORT" "$db" < "$sql" || exit 2
  done
done
echo 'OK'

