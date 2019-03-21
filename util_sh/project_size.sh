#!/bin/bash
if [ -z "${PG_PASS}" ]
then
  echo "$0: you need to specify PG_PASS=..."
  exit 1
fi
if [ -z "${PG_DB}" ]
then
  echo "$0: you need to specify PG_DB=..."
  exit 2
fi
if [ -z "$1" ]
then
  echo "$0: you need to specify date YYYY-MM-DD as an argument"
  exit 3
fi
GHA2DB_LOCAL=1 GHA2DB_SKIPTIME=1 GHA2DB_SKIPLOG=1 runq util_sql/project_size.sql {{exclude_bots}} "`cat util_sql/exclude_bots.sql`" {{date}} "${1}"
