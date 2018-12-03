#!/bin/bash
if [ -z "$1" ]
then
  echo "$0: you need to provide db name"
  exit 1
fi
echo "Dropping $1"
./devel/db.sh psql postgres -c "select pg_terminate_backend(pid) from pg_stat_activity where datname = '$1'"
./devel/db.sh psql postgres -c "drop database $1"
echo "Dropped $1"
