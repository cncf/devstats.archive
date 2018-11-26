#!/bin/bash
# PG_PASS=... PG_DB=allprj ./devel/get_activity_repo_groups.sh '2018-01-31 16:00:00' '2018-01-31 17:00:00'
GHA2DB_LOCAL=1 ./runq metrics/shared/activity_repo_groups.sql {{from}} "$1" {{to}} "$2" {{n}} 1 {{exclude_bots}} "`cat util_sql/exclude_bots.sql`"
