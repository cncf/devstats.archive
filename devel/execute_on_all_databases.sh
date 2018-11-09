#!/bin/bash
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
    ./devel/db.sh psql "$db" < "$sql" || exit 2
  done
done
echo 'OK'

