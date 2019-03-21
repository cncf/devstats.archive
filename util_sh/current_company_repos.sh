#!/bin/bash
if ( [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ] || [ -z "$4" ] )
then
  echo "$0: required DB name, event types, company name(s) and CSV file output, for example allprj \"'PushEvent', 'IssuesEvent'\" \"'ZTE', 'ZTE Corporation'\" output.csv"
  exit 1
fi
GHA2DB_LOCAL=1 GHA2DB_SKIPTIME=1 GHA2DB_SKIPLOG=1 GHA2DB_CSVOUT="$4" PG_DB="$1" runq ./util_sql/company_repo_names.sql {{companies}} "$3" {{event_types}} "$2"
