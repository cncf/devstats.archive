#!/bin/sh
if [ -z "$PG_PASS" ]
then
  echo "$0: you need to specify PG_PASS env variable"
  exit 1
fi
rm actors.txt
. ./devel/all_dbs.sh || exit 2
for db in $all
do
  echo "DB: $db"
  ./devel/db.sh psql -tA $db < ./util_sql/actors.sql >> actors.txt
done
cat actors.txt | sort | uniq > actors.tmp
mv actors.tmp actors.txt
cat actors.txt | wc -l
