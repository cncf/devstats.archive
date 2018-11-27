#!/bin/bash
if ( [ -z "$1" ] || [ -z "$2" ] || [ -z "$PG_PASS" ] )
then
  echo "PG_PASS=... PG_DB=db $0 date_from date_to"
  exit 1
fi
GHA2DB_LOCAL=1 GHA2DB_SKIPTIME=1 GHA2DB_SKIPLOG=1 ./runq metrics/prometheus/reviews_per_user.sql {{exclude_bots}} "`cat util_sql/exclude_bots.sql`" {{n}} 1 {{from}} "$1" {{to}} "$2"
