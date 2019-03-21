#!/bin/bash
if [ -z "$PG_PASS" ]
then
  echo "$0: you need to specify PG_PASS env variable"
  exit 1
fi
if [ -z "$1" ]
then
  echo "$0: you need to provide date argument"
  exit 1
fi
GHA2DB_LOCAL=1 GHA2DB_SKIPTIME=1 GHA2DB_SKIPLOG=1 PG_DB=gha GHA2DB_CSVOUT="new_contributors.csv" runq util_sql/new_contributors.sql {{exclude_bots}} "`cat util_sql/exclude_bots.sql`" {{date}} "$1"
