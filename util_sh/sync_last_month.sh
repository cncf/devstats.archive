#!/bin/bash
GHA2DB_MIN_GHAPI_POINTS=2000 GHA2DB_MAX_GHAPI_WAIT=3601 GHA2DB_LOCAL=1 PG_DB=gha GHA2DB_ISSUES_SYNC_SQL=`cat ./util_sql/recent_issues_milestones.sql` FROM1='{{milestones}}' TO1="'v1.10', 'v1.11', 'v1.12'" ./sync_issues
GHA2DB_MIN_GHAPI_POINTS=2000 GHA2DB_MAX_GHAPI_WAIT=3601 GHA2DB_LOCAL=1 PG_DB=gha GHA2DB_ISSUES_SYNC_SQL=`cat ./util_sql/recent_issues.sql` FROM1='{{from}}' TO1='1 weeks' FROM2='{{to}}' TO2='0 weeks' ./sync_issues
GHA2DB_MIN_GHAPI_POINTS=2000 GHA2DB_MAX_GHAPI_WAIT=3601 GHA2DB_LOCAL=1 PG_DB=gha GHA2DB_ISSUES_SYNC_SQL=`cat ./util_sql/recent_issues.sql` FROM1='{{from}}' TO1='2 weeks' FROM2='{{to}}' TO2='1 weeks' ./sync_issues
GHA2DB_MIN_GHAPI_POINTS=2000 GHA2DB_MAX_GHAPI_WAIT=3601 GHA2DB_LOCAL=1 PG_DB=gha GHA2DB_ISSUES_SYNC_SQL=`cat ./util_sql/recent_issues.sql` FROM1='{{from}}' TO1='3 weeks' FROM2='{{to}}' TO2='2 weeks' ./sync_issues
GHA2DB_MIN_GHAPI_POINTS=2000 GHA2DB_MAX_GHAPI_WAIT=3601 GHA2DB_LOCAL=1 PG_DB=gha GHA2DB_ISSUES_SYNC_SQL=`cat ./util_sql/recent_issues.sql` FROM1='{{from}}' TO1='4 weeks' FROM2='{{to}}' TO2='3 weeks' ./sync_issues
GHA2DB_MIN_GHAPI_POINTS=2000 GHA2DB_MAX_GHAPI_WAIT=3601 GHA2DB_LOCAL=1 PG_DB=gha GHA2DB_ISSUES_SYNC_SQL=`cat ./util_sql/recent_issues.sql` FROM1='{{from}}' TO1='5 weeks' FROM2='{{to}}' TO2='4 weeks' ./sync_issues
