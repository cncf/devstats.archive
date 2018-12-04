#!/bin/bash
if [ -z "${PG_PASS}" ]
then
  echo "You need to set PG_PASS environment variable to run this script"
  exit 1
fi
GHA2DB_LOCAL=1 GHA2DB_SKIPTIME=1 GHA2DB_SKIPLOG=1 PG_DB=devstats ./runq util_sql/get_keywords.sql {{msg}} error > out
cat out | less
echo "This output is saved to 'out' file"
