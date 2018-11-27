#!/bin/bash
. ./devel/all_dbs.sh || exit 2
for db in $all
do
  ./devel/db.sh psql "$db" < ./util_sql/vars_table.sql || exit 1
done
echo 'OK'
