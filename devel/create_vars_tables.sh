#!/bin/bash
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
for proj in $all
do
  sudo -u postgres psql "$proj" < ./util_sql/vars_table.sql || exit 1
done
echo 'OK'
