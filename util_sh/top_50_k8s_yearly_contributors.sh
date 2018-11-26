#!/bin/bash
if [ -z "$PG_PASS" ]
then
  echo "$0: you need to specify PG_PASS env variable"
  exit 1
fi
GHA2DB_LOCAL=1 GHA2DB_SKIPTIME=1 GHA2DB_SKIPLOG=1 PG_HOST=teststats.cncf.io PG_DB=gha GHA2DB_CSVOUT="top_50_k8s_yearly_contributors.csv" ./runq ./util_sql/top_50_k8s_yearly_contributors.sql {{exclude_bots}} "`cat util_sql/exclude_bots.sql`"
