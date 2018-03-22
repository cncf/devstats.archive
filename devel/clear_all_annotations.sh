#!/bin/bash
if [ -z "$IDB_PASS" ]
then
  echo "$0: IDB_PASS environment variable must be set"
  exit 1
fi
if [ -z "$ONLY" ]
then
  host=`hostname`
  if [ $host = "cncftest.io" ]
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
    echo "Clearing annotations data on $db"
    if [ -z "$IDB_HOST" ]
    then
      echo "drop series from annotations" | influx -username gha_admin -password "$IDB_PASS" -database "$db" || exit 1
      echo "drop series from quick_ranges" | influx -username gha_admin -password "$IDB_PASS" -database "$db" || exit 2
      echo "drop series from computed" | influx -username gha_admin -password "$IDB_PASS" -database "$db" || exit 3
    else
      echo "drop series from annotations" | influx -host "${IDB_HOST}" -username gha_admin -password "$IDB_PASS" -database "$db" || exit 4
      echo "drop series from quick_ranges" | influx -host "${IDB_HOST}" -username gha_admin -password "$IDB_PASS" -database "$db" || exit 5
      echo "drop series from computed" | influx -host "${IDB_HOST}" -username gha_admin -password "$IDB_PASS" -database "$db" || exit 6
    fi
done
echo 'OK'
