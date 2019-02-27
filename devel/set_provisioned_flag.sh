#!/bin/bash
if [ -z "$1" ]
then
  echo "$0: You need to provide database name as an argument"
  exit 1
fi
if [ -z "$PG_PASS" ]
then
  echo "$0: You need to set PG_PASS environment variable to run this script"
  exit 2
fi
./devel/db.sh psql "$1" -c "insert into gha_computed(metric, dt) select 'provisioned', now() where not exists(select 1 from gha_computed where metric = 'provisioned')" || exit 3
echo "database '$1' marked as provisioned"
