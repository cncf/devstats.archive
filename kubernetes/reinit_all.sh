#!/bin/bash
./grafana/influxdb_recreate.sh temp || exit 1
IDB_DB=temp GHA2DB_LOCAL=1 GHA2DB_CMDDEBUG=1 GHA2DB_RESETIDB=1 ./gha2db_sync || exit 1
./grafana/influxdb_recreate.sh gha || exit 1
./idb_backup temp gha
