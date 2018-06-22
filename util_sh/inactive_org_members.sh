#!/bin/bash
if [ -z "$1" ]
then
  echo "$0: you must specify period, for example '3 months'"
  exit 1
fi
if [ -z "$PG_PASS" ]
then
  echo "$0: you must provide database password via PG_PASS=..., you can select non-default database via PG_DB=..."
  exit 2
fi
GHA2DB_SKIPTIME=1 GHA2DB_SKIPLOG=1 GHA2DB_CSVOUT=util_sql/inactive_org_members.csv ./runq util_sql/inactive_org_members.sql {{period}} "$1"
