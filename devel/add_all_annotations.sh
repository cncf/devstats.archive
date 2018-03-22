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
    all=`cat ./devel/all_test_projects.txt`
  else
    all=`cat ./devel/all_prod_projects.txt`
  fi
else
  all=$ONLY
fi
for proj in $all
do
  echo "Adding annotations data for $proj"
  ./$proj/annotations.sh
done
echo 'OK'
