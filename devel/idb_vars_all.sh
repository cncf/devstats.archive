#!/bin/bash
if [ -z "${IDB_PASS}" ]
then
  echo "You need to set IDB_PASS environment variable to run this script"
  exit 1
fi
if [ -z "$ONLY" ]
then
  host=`hostname`
  if [ $host = "cncftest.io" ]
  then
    all=`cat ./devel/all_test_projects.txt`
  else
    all=`cat ./devel/all_prod_projects.txt`
  fi
else
  all=$ONLY
fi
for f in $all
do
    db=$f
    if [ $f = "kubernetes" ]
    then
      db="gha"
    elif [ $f = "all" ]
    then
      db="allprj"
    fi
    echo "Project: $f, IDB: $db"
    echo "drop series from vars" | influx -username gha_admin -password "$IDB_PASS" -database "$db" || exit 1
    GHA2DB_LOCAL=1 GHA2DB_PROJECT=$f IDB_DB=$db ./idb_vars || exit 2
done
echo 'OK'
