#!/bin/bash
if [ -z "${FROM}" ]
then
  echo "You need to set FROM, example FROM=abc FILES='f1 f2' $0"
  exit 1
fi
if [ -z "${FILES}" ]
then
  echo "You need to set FILES, example FROM=abc FILES='f1 f2' $0"
  exit 3
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
FROM="    \"$FROM\""
for proj in $all
do
  echo "Project: $proj"
  TO="    \"$proj\""
  for f in ${FILES}
  do
    f="./grafana/dashboards/$proj/$f"
    echo "FROM=$FROM TO=$TO f=$f"
    MODE=ss FROM=$FROM TO=$TO ./replacer $f || exit 1
  done
done
echo 'OK'
