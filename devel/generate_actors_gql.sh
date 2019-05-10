#!/bin/bash
# Run inside 'devstats' image pod shell:
if ( [ -z "${PG_PASS}" ] || [ -z "${PG_HOS}T" ] )
then
  echo "$0: you need to set PG_HOST=... and PG_PASS=... to run this script"
  exit 1
fi
PGPASSWORD="${PG_PASS}" psql -h "${PG_HOST}" -U gha_admin -tA graphql < ./util_sql/actors.sql
PGPASSWORD="${PG_PASS}" psql -h "${PG_HOST}" -U gha_admin -tA graphqljs < ./util_sql/actors.sql
