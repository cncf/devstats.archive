#!/bin/bash
if [ -z "$PG_PASS" ]
then
  echo "$0: you need to specify PG_PASS env variable"
  exit 1
fi
if ( [ -z "$1" ] || [ -z "$2" ]  || [ -z "$3" ] )
then
  echo "$0: you need to provide types, date from and date to arguments"
  echo "$0: example: \"'PushEvent', 'IssuesEvent', 'PullRequestEvent'\" '2017-07-01 2017-08-01"
  exit 1
fi
GHA2DB_LOCAL=1 GHA2DB_SKIPTIME=1 GHA2DB_SKIPLOG=1 GHA2DB_CSVOUT="velocity.csv" runq util_sql/velocity.sql {{exclude_bots}} "`cat util_sql/exclude_bots.sql`" {{types}} "$1" {{date_from}} "$2" {{date_to}} "$3"
