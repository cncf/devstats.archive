#!/bin/bash
if [ -z "$PG_HOST" ]
then
  PG_HOST=127.0.0.1
fi

if [ -z "$PG_PORT" ]
then
  PG_PORT=5432
fi
if [ "$1" = "" ]
then
  echo "Usage: $0 dbname"
  exit 1
fi
sudo -u postgres psql -h "$PG_HOST" -p "$PG_PORT" -tA $1 < ./util_sql/actors.sql > actors.txt
cat actors.txt | sort | uniq > actors.tmp
mv actors.tmp actors.txt
cat actors.txt | wc -l
