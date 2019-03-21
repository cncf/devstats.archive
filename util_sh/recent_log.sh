#!/bin/bash
if [ -z "$1" ]
then
  echo "You need to set limit: N"
  exit 1
fi
if [ -z "$PG_PASS" ]
then
  echo "You need to provide postgres password via PG_PASS=... $0 $*"
  exit 2
fi
GHA2DB_LOCAL=1 GHA2DB_SKIPTIME=1 GHA2DB_SKIPLOG=1 PG_DB=devstats runq util_sql/recent_log.sql {{lim}} "$1"
