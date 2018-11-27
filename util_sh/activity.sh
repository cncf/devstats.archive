#!/bin/bash
if [ -z "$1" ]
then
  echo "You need to set period in format 'period,from,to' - either specify period or from,to pair."
  exit 1
fi
if [ -z "$PG_PASS" ]
then
  echo "You need to provide postgres password via PG_PASS=... $0 $*"
  exit 2
fi
GHA2DB_LOCAL=1 GHA2DB_SKIPTIME=1 GHA2DB_SKIPLOG=1 ./runq util_sql/proj_activity.sql qr "$1" {{exclude_bots}} "`cat util_sql/exclude_bots.sql`"
