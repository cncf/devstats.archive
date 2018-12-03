#!/bin/bash
. ./devel/all_dbs.sh || exit 2
for db in $all
do
    echo "Clearing annotations data on $db"
    ./devel/db.sh psql "$db" -c "delete from sannotations" || exit 1
    ./devel/db.sh psql "$db" -c "delete from tquick_ranges" || exit 1
    ./devel/db.sh psql "$db" -c "delete from gha_computed" || exit 1
done
echo 'OK'
