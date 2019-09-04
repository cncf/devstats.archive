#!/bin/bash
if [ -z "$1" ]
then
  echo "$0: you need to provide org name"
  exit 1
fi
if [ -z "$2" ]
then
  echo "$0: you need to provide period name, like 'month.201907' or 'year.2018'"
  exit 2
fi
function finish {
    rm -f /tmp/org_name_changes_complex.sql
}
trap finish EXIT

cp util_sql/org_name_changes_complex.sql /tmp/org_name_changes_complex.sql || exit 3
FROM="{{org}}" TO="$1" MODE=ss replacer /tmp/org_name_changes_complex.sql || exit 4
FROM="{{period}}" TO="$2" MODE=ss replacer /tmp/org_name_changes_complex.sql || exit 5
cat /tmp/org_name_changes_complex.sql | bq --format=csv --headless query --use_legacy_sql=true -n 1000000 --use_cache
