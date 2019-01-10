#!/bin/bash
if [ -z "$PG_PASS" ]
then
  echo "$0: You need to set PG_PASS environment variable to run this script"
  exit 1
fi
if [ -z "$1" ]
then
  echo "$0: You need to pass 'period ago' as a first argument, for example '1 year'"
  exit 2
fi
if [ -z "$2" ]
then
  echo "$0: You need to pass downcased company names as a second argument, for example \"'google', 'red hat'\""
  exit 3
fi
GHA2DB_LOCAL=1 GHA2DB_CSVOUT="company_prs.csv" ./runq ./util_sql/company_prs.sql  {{ago}} "$1" {{companies}} "$2"
