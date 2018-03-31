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
for proj in $all
do
    db=$proj
    if [ "$proj" = "kubernetes" ]
    then
      db="gha"
    elif [ "$proj" = "all" ]
    then
      db="allprj"
    fi
    echo "Project: $proj, IDB: $db"
    echo "drop series from vars" | influx -username gha_admin -password "$IDB_PASS" -database "$db" || exit 1
    GHA2DB_LOCAL=1 GHA2DB_PROJECT=$proj IDB_DB=$db ./idb_vars || exit 2
done
echo 'OK'
