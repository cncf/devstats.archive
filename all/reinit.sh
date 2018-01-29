#!/bin/sh
./grafana/influxdb_recreate.sh all_temp || exit 1
GHA2DB_CMDDEBUG=1 GHA2DB_RESETIDB=1 GHA2DB_LOCAL=1 GHA2DB_PROJECT=all PG_DB=all IDB_DB=all_temp ./gha2db_sync || exit 2
./grafana/influxdb_recreate.sh all || exit 3
./idb_backup all_temp all || exit 4
./grafana/influxdb_drop.sh all_temp
