#!/bin/bash
# Run inside 'devstats' image pod shell:
if ( [ -z "${PG_PASS}" ] || [ -z "${PG_HOS}T" ] )
then
  echo "$0: you need to set PG_HOST=... and PG_PASS=... to run this script"
  exit 1
fi
PGPASSWORD="${PG_PASS}" psql -h "${PG_HOST}" -U gha_admin -tA iovisor < ./util_sql/actors.sql
PGPASSWORD="${PG_PASS}" psql -h "${PG_HOST}" -U gha_admin -tA mininet < ./util_sql/actors.sql
PGPASSWORD="${PG_PASS}" psql -h "${PG_HOST}" -U gha_admin -tA opennetworkinglab < ./util_sql/actors.sql
PGPASSWORD="${PG_PASS}" psql -h "${PG_HOST}" -U gha_admin -tA opensecuritycontroller < ./util_sql/actors.sql
PGPASSWORD="${PG_PASS}" psql -h "${PG_HOST}" -U gha_admin -tA openswitch < ./util_sql/actors.sql
PGPASSWORD="${PG_PASS}" psql -h "${PG_HOST}" -U gha_admin -tA p4lang < ./util_sql/actors.sql
PGPASSWORD="${PG_PASS}" psql -h "${PG_HOST}" -U gha_admin -tA openbmp < ./util_sql/actors.sql
PGPASSWORD="${PG_PASS}" psql -h "${PG_HOST}" -U gha_admin -tA tungstenfabric < ./util_sql/actors.sql
PGPASSWORD="${PG_PASS}" psql -h "${PG_HOST}" -U gha_admin -tA cord < ./util_sql/actors.sql
PGPASSWORD="${PG_PASS}" psql -h "${PG_HOST}" -U gha_admin -tA zephyr < ./util_sql/actors.sql
PGPASSWORD="${PG_PASS}" psql -h "${PG_HOST}" -U gha_admin -tA linux < ./util_sql/actors.sql
