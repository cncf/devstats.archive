#!/bin/bash
if ( [ -z "$PG_PASS" ] || [ -z "$PG_DB" ] || [ -z "$1" ] )
then
  echo "$0: you need to set PG_DB and PG_PASS env variables and provide number of companies as an argument to use this script"
  exit 1
fi
GHA2DB_LOCAL=1 ./runq metrics/shared/companies_tags.sql {{lim}} $1 ' sub.name' " string_agg(sub.name, ',')" {{exclude_bots}} "`cat util_sql/exclude_bots.sql`"
