#!/bin/bash
./grafana/influxdb_recreate.sh test || exit 1
IDB_DB=test GHA2DB_SKIPPDB=1 GHA2DB_LOCAL=1 GHA2DB_CMDDEBUG=1 GHA2DB_RESETIDB=1 ./gha2db_sync || exit 1
