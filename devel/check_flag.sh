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
if [ -z "$3" ]
then
  echo "$0: you need to provide flag expected value (0 or 1)"
  exit 3
fi
if [ -z "$PG_PASS" ]
then
  echo "$0: You need to set PG_PASS environment variable to run this script"
  exit 4
fi
user=gha_admin
if [ ! -z "${PG_USER}" ]
then
  user="${PG_USER}"
fi

echo "checking $2 flag on $1 database, expected value $3"
exists=`PG_USER="${user}" ./devel/db.sh psql "$1" -tAc "select 1 from gha_computed where metric = '$2' union select 0 order by 1 desc limit 1"` || exit 5
if [ ! "$exists" = "$3" ]
then
  echo "$1 expecting $2 to be $3, got $exists"
  exit 6
fi
