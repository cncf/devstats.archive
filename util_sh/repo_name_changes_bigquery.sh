#!/bin/bash
if [ -z "$1" ]
then
  echo "$0: you need to provide repo name as org/repo"
  exit 1
fi
function finish {
    rm -f /tmp/repo_name_changes_bigquery.sql
}
trap finish EXIT

cp util_sql/repo_name_changes_bigquery.sql /tmp/repo_name_changes_bigquery.sql || exit 2
FROM="{{org_repo}}" TO="$1" MODE=ss replacer /tmp/repo_name_changes_bigquery.sql || exit 3
cat /tmp/repo_name_changes_bigquery.sql | bq --format=csv --headless query --use_legacy_sql=true -n 1000000 --use_cache
