#!/bin/bash
if [ -z "$1" ]
then
  echo "$0: you need to provide database name"
  echo "When running manually please copy/link /var/www/html/dbname.dump to current directory and remove after restore"
  exit 1
fi
./devel/drop_psql_db.sh $1
echo "Creating $1"
sudo -u postgres createdb $1
sudo -u postgres pg_restore -d $1 $1.dump
echo "Created $1"
