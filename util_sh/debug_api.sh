#!/bin/bash
./util_sh/debug_ghapi2db.sh > ./ghapi2db.out
GHA2DB_ISSUES_SYNC_SQL=`cat ./util_sql/recent_issues.sql` ./util_sh/sync_issues.sh > ./sync_issues.out
