#!/bin/bash
./devel/drop_ts_tables.sh test || exit 1
PG_DB=gha PG_DB=test GHA2DB_SKIPPDB=1 GHA2DB_LOCAL=1 GHA2DB_CMDDEBUG=1 GHA2DB_RESET_ES_RAW=1 GHA2DB_RESETTSDB=1 ./gha2db_sync || exit 1
