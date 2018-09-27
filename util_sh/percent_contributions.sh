#!/bin/sh
if [ -z "$PG_PASS" ]
then
  echo "$0: you need to specify PG_PASS env variable"
  exit 1
fi
for db in `cat devel/all_test_dbs.txt`
do
  echo "$db"
  PG_DB=$db GHA2DB_CSVOUT="percent_contributions_${db}.csv" GHA2DB_SKIPTIME=1 GHA2DB_SKIPLOG=1 ./runq util_sql/percent_contributions.sql {{exclude_bots}} "`cat util_sql/exclude_bots.sql`" > /dev/null
done
