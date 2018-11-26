#!/bin/bash
if [ -z "${PG_PASS}" ]
then
  echo "$0: you need to set PG_PASS environment variable to run this script"
  exit 1
fi
if [ -z "${1}" ]
then
  echo "$0: you need to specify period name as an argument"
  exit 2
fi
GHA2DB_LOCAL=1 GHA2DB_SKIPTIME=1 GHA2DB_SKIPLOG=1 PG_DB=devstats ./runq util_sql/check_calcs.sql {{period}} "${1}" > out
cat out | less
echo "This output is saved to 'out' file"
