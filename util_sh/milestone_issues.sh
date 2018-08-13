#!/bin/bash
if ( [ -z "$1" ] || [ -z "$PG_PASS" ] )
then
  echo "PG_PASS=... $0 milestone_name"
  exit 1
fi
GHA2DB_SKIPTIME=1 GHA2DB_SKIPLOG=1 ./runq util_sql/milestone_issues.sql {{milestone}} "$1"
