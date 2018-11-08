#!/bin/bash
if [ -z "$1" ]
then
  echo "$0: need user name argument"
  exit 1
fi
if [ -z "$2" ]
then
  echo "$0: need database name argument"
  exit 1
fi
if [ -z "$PG_HOST" ]
then
  PG_HOST=127.0.0.1
fi

if [ -z "$PG_PORT" ]
then
  PG_PORT=5432
fi
proj=$2
sudo -u postgres psql -h "$PG_HOST" -p "$PG_PORT" -c "grant connect on database \"$proj\" to \"$1\"" || exit 1
sudo -u postgres psql -h "$PG_HOST" -p "$PG_PORT" -c "grant usage on schema \"public\" to \"$1\"" || exit 1
tables=`sudo -u postgres psql -h "$PG_HOST" -p "$PG_PORT" $proj -qAntc '\dt' | cut -d\| -f2`
for table in $tables
do
  echo -n "$proj: $table "
  sudo -u postgres psql -h "$PG_HOST" -p "$PG_PORT" $proj -c "grant select on $table to \"$1\"" || exit 1
done
