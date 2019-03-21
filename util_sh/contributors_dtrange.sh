#!/bin/bash
if [ -z "$PG_PASS" ]
then
  echo "$0: you need to specify PG_PASS env variable"
  exit 1
fi
if ( [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ] )
then
  echo "$0: you need to specify dtfrom dtto n"
  exit 1
fi
GHA2DB_LOCAL=1 GHA2DB_SKIPTIME=1 GHA2DB_SKIPLOG=1 PG_HOST=teststats.cncf.io PG_DB=gha GHA2DB_CSVOUT="contributors_dtrange.csv" runq ./util_sql/contributors_dtrange.sql {{exclude_bots}} "`cat util_sql/exclude_bots.sql`" {{from}} "$1" {{to}} "$2" {{n}} "$3" > out
