#!/bin/bash
if [ -z "$PG_DB" ]
then
  echo "$0: you must specify PG_DB"
  exit 1
fi
if [ -z "$PG_PASS" ]
then
  echo "$0: you must specify PG_PASS"
  exit 2
fi
if ( [ -z "$1" ] || [ -z "$2" ] )
then
  echo "$0: you must specify dt_from and dt_to as an arguments"
  exit 3
fi
GHA2DB_LOCAL=1 runq util_sql/delete_all_range.sql {{from}} "$1" {{to}} "$2"
