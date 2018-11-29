#!/bin/bash
if [ -z "${PG_PASS}" ]
then
  echo "You need to set PG_PASS environment variable to run this script"
  exit 1
fi
docker run -e GHA2DB_ES_URL="http://172.17.0.1:19200" -e GHA2DB_USE_ES=1 -e GHA2DB_USE_ES_RAW=1 -e PG_PORT=65432 -e PG_HOST="172.17.0.1" -e PG_PASS="${PG_PASS}" -e GHA2DB_PROJECT=cord -e PG_DB=cord -it devstats calc_metric multi_row_single_column ./metrics/shared/commits_repo_groups.sql '2018-11-01 0' '2018-11-29 9' d multivalue
