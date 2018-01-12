#!/bin/sh
GHA2DB_SKIPTIME=1 GHA2DB_SKIPLOG=1 ./runq util_sql/proj_activity.sql {{lim}} $1
