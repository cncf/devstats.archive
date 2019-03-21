#!/bin/bash
if [ -z "$PG_PASS" ]
then
  echo "$0: you need to specify PG_PASS env variable"
  exit 1
fi
if ( [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ] || [ -z "$4" ] || [ -z "$5" ] )
then
  echo "$0: you need to provide arguments: start_date companies types column_to_count output.csv"
  echo "Example: $0 '2014-06-01' \"'Google', 'Red Hat'\" \"'PushEvent', 'IssuesEvent', 'PullRequestEvent'\" actor_id comps.csv"
  echo "Special env variables:"
  echo "BOTS=true or BOTH=false - include or exclude bots events, default is to exclude bots (just like BOTS=false)"
  echo "SKIPFROM=true/false - skip date from condition, so if set to true it will calculate cumulative monthly data (sum to current month), default false"
  echo "SKIPTO=true/false - skip date to condition, so if set to true it will calculate cumulative monthly data (sum from current month) , default false"
  echo "If both SKIPFROM and SKIPTO are false, data for separate month is calculated"
  echo "Setting both SKIPFROM and SKIPTO to true will display all time data N month times (so it is rather strange use case but possible)"
  exit 1
fi

if [ -z "$BOTS" ]
then
  BOTS=false
fi

if [ -z "$SKIPFROM" ]
then
  SKIPFROM=false
fi

if [ -z "$SKIPTO" ]
then
  SKIPTO=false
fi

COLNAME=${5%.*}

GHA2DB_LOCAL=1 GHA2DB_SKIPTIME=1 GHA2DB_SKIPLOG=1 PG_DB=gha GHA2DB_CSVOUT="$5" runq util_sql/monthly.sql {{exclude_bots}} "`cat util_sql/exclude_bots.sql`" {{bots}} "$BOTS" {{colname}} "$COLNAME"  {{skipfrom}} "$SKIPFROM" {{skipto}} "$SKIPTO" {{start_date}} "$1" {{companies}} "$2" {{types}} "$3" {{col}} "$4"
