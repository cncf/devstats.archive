#!/bin/bash
if [ -z "$PG_PASS" ]
then
  echo "$0: PG_PASS environment variable must be set"
  exit 1
fi
if [ -z "$ONLY" ]
then
  host=`hostname`
  if [ $host = "teststats.cncf.io" ]
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
  if [ -f "./$proj/annotations.sh" ]
  then
    echo "Adding annotations data for project: $proj, db: $db (using project specific script)"
    ./$proj/annotations.sh
  else
    echo "Adding annotations data for project: $proj, db: $db (using shared script)"
    GHA2DB_PROJECT=$proj PG_DB=$db ./shared/annotations.sh
  fi
done
echo 'OK'
