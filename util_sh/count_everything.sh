#!/bin/bash
if [ -z "$1" ]
then
  echo "$0: need database name argument"
  exit 1
fi
if [ -z "$PG_PASS" ]
then
  echo "$0: You need to set PG_PASS environment variable to run this script"
  exit 2
fi
tables=`./devel/db.sh psql $1 -qAntc '\dt' | cut -d\| -f2`
> out
for table in $tables
do
  echo -n "$table: " >> out
  ./devel/db.sh psql $1 -qAntc "select count(*) from \"$table\"" >> out || exit 3
done
cat out | sort -k 2 -n
