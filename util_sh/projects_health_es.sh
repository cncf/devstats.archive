#!/bin/bash
if [ -z "$PG_PASS" ]
then
  echo "$0: you need to set PG_PASS=..."
  exit 1
fi
if [ -z "$GHA2DB_ES_URL" ]
then
  echo "$0: you need to set GHA2DB_ES_URL=..."
  exit 2
fi
GHA2DB_PROJECT=all PG_DB=allprj GHA2DB_SKIPTSDB=1 GHA2DB_USE_ES_ONLY=1 GHA2DB_USE_ES=1 GHA2DB_LOCAL=1 ./calc_metric multi_row_single_column ./metrics/shared/projects_health.sql '2014-01-01 0' '2019-02-14 8' d 'hist,merge_series:projects_health,custom_data'
