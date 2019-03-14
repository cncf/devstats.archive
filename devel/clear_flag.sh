#!/bin/bash
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
user=gha_admin
if [ ! -z "${PG_USER}" ]
then
  user="${PG_USER}"
fi
PG_USER="${user}" ./devel/db.sh psql "$1" -c "delete from gha_computed where metric = '$2'" || exit 4
echo "database '$1' $2 flag cleared"
