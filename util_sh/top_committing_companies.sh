#!/bin/bash
if [ -z "$1" ]
then
  echo "$0: you need to provide number of companies to display as an arg"
  exit 1
fi
if [ -z "$PG_PASS" ]
then
  echo "$0: you need to set PG_PASS to run this script"
  exit 1
fi
GHA2DB_LOCAL=1 GHA2DB_SKIPTIME=1 GHA2DB_SKIPLOG=1 ./runq util_sql/top_committing_companies.sql {{exclude_bots}} "`cat util_sql/exclude_bots.sql`" {{lim}} "$1"
