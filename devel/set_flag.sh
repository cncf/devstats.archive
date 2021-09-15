#!/bin/bash
# DURABLE=1 - db command must succeed, if not wait until it does.
if [ -z "$1" ]
then
  echo "$0: you need to provide database name as an argument"
  exit 1
fi
if [ -z "$2" ]
then
  echo "$0: you need to provide flag as a second argument"
  exit 2
fi
if [ -z "$PG_PASS" ]
then
  echo "$0: You need to set PG_PASS environment variable to run this script"
  exit 3
fi
seconds=60
if [ ! -z "$3" ]
then
  seconds=$3
fi
user=gha_admin
if [ ! -z "${PG_USER}" ]
then
  user="${PG_USER}"
fi
while true
do
  echo "setting $2 flag on '$1' database"
  if [ -z "$DURABLE" ]
  then
    PG_USER="${user}" ./devel/db.sh psql "$1" -c "insert into gha_computed(metric, dt) select '$2', now() where not exists(select 1 from gha_computed where metric = '$2')" || exit 4
  else
    PG_USER="${user}" ./devel/db.sh psql "$1" -c "insert into gha_computed(metric, dt) select '$2', now() where not exists(select 1 from gha_computed where metric = '$2')"
    if [ ! "$?" = "0" ]
    then
      echo "command failed, waiting $seconds seconds"
      sleep $seconds
      continue
    fi
  fi
  echo "database '$1' marked as $2"
  break
done
