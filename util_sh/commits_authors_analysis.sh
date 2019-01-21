#!/bin/bash
if [ -z "${PG_PASS}" ]
then
  echo "You need to set PG_PASS environment variable to run this script"
  exit 1
fi
GHA2DB_LOCAL=1 PG_DB=allprj GHA2DB_CSVOUT="report_alltime.csv" ./runq ./util_sql/commits_authors_analysis.sql {{exclude_bots}} "`cat util_sql/exclude_bots.sql`" {{skip_companies}} "'*unknown*', 'NotFound', '(Unknown)', ''" {{skip_repo_groups}} "'OPA', 'SPIFFE', 'SPIRE', 'CloudEvents', 'Telepresence', 'OpenMetrics', 'TiKV', 'Cortex', 'Buildpacks', 'Falco', 'Dragonfly', 'Virtual Kubelet'" {{user}} author qr '10 years,,' > report_alltime.txt
GHA2DB_LOCAL=1 PG_DB=allprj GHA2DB_CSVOUT="report_6months.csv" ./runq ./util_sql/commits_authors_analysis.sql {{exclude_bots}} "`cat util_sql/exclude_bots.sql`" {{skip_companies}} "'*unknown*', 'NotFound', '(Unknown)', ''" {{skip_repo_groups}} "'OPA', 'SPIFFE', 'SPIRE', 'CloudEvents', 'Telepresence', 'OpenMetrics', 'TiKV', 'Cortex', 'Buildpacks', 'Falco', 'Dragonfly', 'Virtual Kubelet'" {{user}} author qr '6 months,,' > report_6months.txt
