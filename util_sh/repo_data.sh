#!/bin/bash
if [ -z "$1" ]
then
  echo "$0: you need to provide repo name as org/repo"
  exit 1
fi
function finish {
  rm -f /tmp/repo_data.sql
}
trap finish EXIT

cp util_sql/repo_data.sql /tmp/repo_data.sql || exit 2
FROM="{{org_repo}}" TO="$1" MODE=ss replacer /tmp/repo_data.sql || exit 3
cat /tmp/repo_data.sql | bq --format=csv --headless query --use_legacy_sql=true -n 1000000 --use_cache
