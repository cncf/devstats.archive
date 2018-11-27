#!/bin/bash
host=`hostname`
if [ "$host" = "teststats.cncf.io" ]
then
  from="https://devstats.cncf.io/"
else
  from="https://teststats.cncf.io/"
fi
. ./devel/all_dbs.sh || exit 2
for db in $all
do
  echo "DB: $db"
  wget ${from}${db}.dump
done
echo 'OK'
