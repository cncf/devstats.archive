#!/bin/bash
if ( [ -z "$PG_PASS" ] || [ -z "$PG_DB" ] || [ -z "$GHA2DB_PROJECT" ] )
then
  echo "$0: you need to set GHA2DB_PROJECT, PG_DB and PG_PASS env variables to use this script"
  exit 1
fi
proj=$GHA2DB_PROJECT
./runq metrics/$proj/companies_tags.sql {{lim}} $1 ' sub.name' " string_agg(sub.name, ',')" {{exclude_bots}} "`cat util_sql/exclude_bots.sql`"
