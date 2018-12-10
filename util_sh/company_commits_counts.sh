#!/bin/bash
if [ -z "$PG_PASS" ]
then
  echo "$0: you need to specify PG_PASS env variable"
  exit 1
fi
if [ -z "$1" ]
then
  echo "$0: you need to specify number of companies to show as a first argument"
  exit 2
fi
GHA2DB_CSVOUT="company_commits_counts.csv" GHA2DB_LOCAL=1 GHA2DB_SKIPTIME=1 GHA2DB_SKIPLOG=1 PG_DB=allprj ./runq ./util_sql/company_commits_counts.sql {{exclude_bots}} "`cat util_sql/exclude_bots.sql`" {{lim}} $1
