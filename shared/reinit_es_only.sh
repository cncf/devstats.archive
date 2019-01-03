#!/bin/bash
# SKIPTEMP=1 skip regenerating data into temporary database and use current database directly
if ( [ -z "$GHA2DB_PROJECT" ] || [ -z "$PG_DB" ] || [ -z "$PG_PASS" ] )
then
  echo "$0: you need to set GHA2DB_PROJECT, PG_DB, PG_PASS env variables to use this script"
  exit 1
fi
user=gha_admin
if [ ! -z "${PG_USER}" ]
then
  user="${PG_USER}"
fi
PG_USER="${user}" ./devel/db.sh psql "$PG_DB" -c "delete from gha_vars" || exit 1
GHA2DB_USE_ES=1 GHA2DB_USE_ES_ONLY=1 GHA2DB_SKIPTSDB=1 GHA2DB_SKIPPDB=1 GHA2DB_LOCAL=1 ./vars || exit 2
GHA2DB_USE_ES=1 GHA2DB_USE_ES_ONLY=1 GHA2DB_SKIPTSDB=1 GHA2DB_SKIPPDB=1 GHA2DB_RESET_ES_RAW=1 GHA2DB_CMDDEBUG=1 GHA2DB_RESETTSDB=1 GHA2DB_LOCAL=1 ./gha2db_sync || exit 3
