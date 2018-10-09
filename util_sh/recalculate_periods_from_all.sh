#!/bin/bash
if [ -z "${PG_PASS}" ]
then
  echo "You need to set PG_PASS environment variable to run this script"
  exit 1
fi
if [ -z "$1" ]
then
  echo "$0: you need to provide date start as a 1st argument: YYYY-MM-DD"
  exit 1
fi
if [ -z "$2" ]
then
  echo "$0: you need to provide periods to calculate as a 2nd argument: 'w:f,m:f,q:f,y:f'"
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
    GHA2DB_PROJECT=$proj PG_DB=$db ./util_sh/recalculate_periods_from.sh "$1" "$2" || exit 1
done
echo 'OK'
