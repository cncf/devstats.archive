#!/bin/sh
./grafana/influxdb_recreate.sh rook_temp || exit 1
GHA2DB_CMDDEBUG=1 GHA2DB_RESETIDB=1 GHA2DB_LOCAL=1 GHA2DB_PROJECT=rook PG_DB=rook IDB_DB=rook_temp ./gha2db_sync || exit 2
./grafana/influxdb_recreate.sh rook || exit 3
./idb_backup rook_temp rook || exit 4
./grafana/influxdb_drop.sh rook_temp
