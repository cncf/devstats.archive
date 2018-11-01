#!/bin/bash
if [ -z "$PG_PASS" ]
then
  echo "$0: you need to specify PG_PASS env variable"
  exit 1
fi
if [ -z "$1" ]
then
  echo "$0: you need to provide start date argument"
  exit 1
fi
GHA2DB_SKIPTIME=1 GHA2DB_SKIPLOG=1 GHA2DB_CSVOUT="csv/${PG_DB}_monthly_data.csv" ./runq util_sql/monthly_data.sql {{exclude_bots}} "`cat util_sql/exclude_bots.sql`" {{start_date}} "$1"
