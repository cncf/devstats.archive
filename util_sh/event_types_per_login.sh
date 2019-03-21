#!/bin/bash
if [ -z "$PG_PASS" ]
then
  echo "$0: you need to specify PG_PASS env variable"
  exit 1
fi
if ( [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ] )
then
  echo "$0: you need to provide companies, starty date, end date arguments"
  echo "Example \"'Google', 'VMware'\" '2014-01-01 '2019-01-01'"
  echo "Use GHA2DB_CSVOUT=filename.csv to save as CSV"
  exit 1
fi
GHA2DB_LOCAL=1 GHA2DB_SKIPTIME=1 GHA2DB_SKIPLOG=1 runq util_sql/event_types_per_login.sql {{companies}} "$1" {{from}} "$2" {{to}} "$3"
