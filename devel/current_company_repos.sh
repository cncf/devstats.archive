#!/bin/bash
if ( [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ] )
then
  echo "$0: required DB name, company name(s) and CSV file output, for example allprj \"'ZTE', 'ZTE Corporation'\" out.csv"
  exit 1
fi
GHA2DB_SKIPTIME=1 GHA2DB_SKIPLOG=1 GHA2DB_CSVOUT="$3" PG_DB="$1" ./runq ./util_sql/company_repo_names.sql {{companies}} "$2"
