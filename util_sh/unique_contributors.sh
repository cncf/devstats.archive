#!/bin/sh
rm actors.txt
if [ -z "$ONLY" ]
then
  host=`hostname`
  if [ $host = "teststats.cncf.io" ]
  then
    all=`cat ./devel/all_test_dbs.txt`
    from="https://devstats.cncf.io/"
  else
    all=`cat ./devel/all_prod_dbs.txt`
    from="https://teststats.cncf.io/"
  fi
else
  all=$ONLY
fi
for db in $all
do
  echo "DB: $db"
  ./devel/db.sh psql -tA $db < ./util_sql/actors.sql >> actors.txt
done
cat actors.txt | sort | uniq > actors.tmp
mv actors.tmp actors.txt
cat actors.txt | wc -l
