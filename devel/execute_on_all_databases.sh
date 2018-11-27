#!/bin/bash
if [ -z "$1" ]
then
  echo "$0: at least one SQL script required"
  exit 1
fi
. ./devel/all_dbs.sh || exit 2
for db in $all
do
  for sql in $*
  do
    echo "Execute script '$sql' on '$db' database"
    ./devel/db.sh psql "$db" < "$sql" || exit 2
  done
done
echo 'OK'

