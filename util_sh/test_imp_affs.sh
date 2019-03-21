#!/bin/bash
./devel/drop_psql_db.sh small
PG_DB=small GHA2DB_LOCAL=1 structure
./devel/db.sh psql small -c "create extension if not exists pgcrypto" || exit 1
GHA2DB_PROJECT=small PG_DB=small GHA2DB_LOCAL=1 gha2db 2018-09-01 0 today now kubernetes
GHA2DB_PROJECT=small PG_DB=small GHA2DB_LOCAL=1 GHA2DB_MGETC=y GHA2DB_SKIPTABLE=1 GHA2DB_INDEX=1 structure
GHA2DB_LOCAL=1 PG_DB=small ./runq scripts/clean_affiliations.sql
GHA2DB_LOCAL=1 PG_DB=small GHA2DB_QOUT=1 import_affs partial.json
GHA2DB_LOCAL=1 PG_DB=small ./runq util_sql/update_country_names.sql
