#!/bin/bash
if [ -z "$1" ]
then
  echo "$0: you need to provide org name"
  exit 1
fi
function finish {
    rm -f /tmp/org_name_changes_bigquery.sql
}
trap finish EXIT

cp util_sql/org_name_changes_bigquery.sql /tmp/org_name_changes_bigquery.sql || exit 2
FROM="{{org}}" TO="$1" MODE=ss ./replacer /tmp/org_name_changes_bigquery.sql || exit 3
cat /tmp/org_name_changes_bigquery.sql | bq --format=csv --headless query --use_legacy_sql=true -n 1000000 --use_cache
