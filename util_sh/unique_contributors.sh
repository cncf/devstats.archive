#!/bin/sh
if [ -z "$PG_HOST" ]
then
  PG_HOST=127.0.0.1
fi

if [ -z "$PG_PORT" ]
then
  PG_PORT=5432
fi
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
  sudo -u postgres psql -h "$PG_HOST" -p "$PG_PORT" -tA $db < ./util_sql/actors.sql >> actors.txt
done
cat actors.txt | sort | uniq > actors.tmp
mv actors.tmp actors.txt
cat actors.txt | wc -l
