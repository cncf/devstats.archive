#!/bin/bash
if [ -z "$PG_PASS" ]
then
  echo "$0: you need to specify PG_PASS env variable"
  exit 1
fi
if [ -z "$1" ]
then
  echo "$0: you need to specify start_date YYYY-MM-DD as an arg"
  exit 1
fi

. ./devel/all_dbs.sh || exit 2
for db in $all
do
  echo "$db"
  GHA2DB_LOCAL=1 PG_DB=$db GHA2DB_CSVOUT="percent_commits_from_${1}_${db}.csv" GHA2DB_SKIPTIME=1 GHA2DB_SKIPLOG=1 runq util_sql/percent_commits.sql {{exclude_bots}} "`cat util_sql/exclude_bots.sql`" {{from}} "$1" > /dev/null
done
