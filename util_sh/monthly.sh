#!/bin/bash
if [ -z "$PG_PASS" ]
then
  echo "$0: you need to specify PG_PASS env variable"
  exit 1
fi
if ( [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ] || [ -z "$4" ] || [ -z "$5" ] || [ -z "$6" ] )
then
  echo "$0: you need to provide arguments: start_date bots companies types column_to_count output.csv"
  echo "Example: $0 '2014-06-01' false \"'Google', 'Red Hat'\" \"'PushEvent', 'IssuesEvent', 'PullRequestEvent'\" actor_id comps.csv"
  exit 1
fi
colname=${6%.*}
GHA2DB_SKIPTIME=1 GHA2DB_SKIPLOG=1 PG_DB=gha GHA2DB_CSVOUT="$6" ./runq util_sql/monthly.sql {{exclude_bots}} "`cat util_sql/exclude_bots.sql`" {{start_date}} "$1" {{bots}} "$2" {{companies}} "$3" {{types}} "$4" {{col}} "$5" {{colname}} "$colname"
