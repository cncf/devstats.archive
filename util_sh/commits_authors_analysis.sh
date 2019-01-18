#!/bin/bash
if [ -z "${PG_PASS}" ]
then
  echo "You need to set PG_PASS environment variable to run this script"
  exit 1
fi
GHA2DB_LOCAL=1 PG_DB=allprj GHA2DB_CSVOUT="report.csv" ./runq ./util_sql/commits_authors_analysis.sql {{exclude_bots}} "`cat util_sql/exclude_bots.sql`" {{skip_companies}} "'NotFound', '(Unknown)', ''" {{user}} committer qr '1 year,,'
