#!/bin/bash
if [ "$1" = "" ]
then
  echo "Usage: $0 dbname"
  exit 1
fi
./devel/db.sh psql -tA $1 < ./util_sql/actors.sql > actors.txt
cat actors.txt | sort | uniq > actors.tmp
mv actors.tmp actors.txt
cat actors.txt | wc -l
