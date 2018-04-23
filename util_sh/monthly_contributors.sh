#!/bin/bash
GHA2DB_SKIPTIME=1 GHA2DB_SKIPLOG=1 PG_DB=gha GHA2DB_CSVOUT="monthly_contributors.csv" ./runq util_sql/monthly_contributors.sql {{start_date}} '2014-01-01'
