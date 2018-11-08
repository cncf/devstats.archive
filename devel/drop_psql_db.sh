#!/bin/bash
if [ -z "$PG_HOST" ]
then
  PG_HOST=127.0.0.1
fi

if [ -z "$PG_PORT" ]
then
  PG_PORT=5432
fi
if [ -z "$1" ]
then
  echo "$0: you need to provide db name"
  exit 1
fi
echo "Dropping $1"
sudo -u postgres psql -h "$PG_HOST" -p "$PG_PORT" -c "select pg_terminate_backend(pid) from pg_stat_activity where datname = '$1'"
sudo -u postgres psql -h "$PG_HOST" -p "$PG_PORT" -c "drop database $1"
echo "Dropped $1"
