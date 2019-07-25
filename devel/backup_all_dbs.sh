#!/bin/bash
if [ -z "$ONLY" ]
then
  dbs=`db.sh psql -tAc 'select datname from pg_database where datistemplate = false'`
else
  dbs="$ONLY"
fi

for db in $dbs
do
  echo "db: $db"
  db.sh pg_dump -Fc "$db" -f "/root/${db}.dump" || rm -f "/root/${db}.dump"
done
