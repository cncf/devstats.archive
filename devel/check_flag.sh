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

exists=`PG_USER="${user}" ./devel/db.sh psql "$1" -tAc "select 1 from gha_computed where metric = '$2'"` || exit 4
if [ ! "$exists" = "1" ]
then
  echo "No $2 flag on $1 database"
  exit 5
fi
