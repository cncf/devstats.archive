#!/bin/sh
./grafana/influxdb_recreate.sh opencontainers_temp || exit 1
GHA2DB_CMDDEBUG=1 GHA2DB_RESETIDB=1 GHA2DB_LOCAL=1 GHA2DB_PROJECT=opencontainers PG_DB=opencontainers IDB_DB=opencontainers_temp ./gha2db_sync || exit 2
./grafana/influxdb_recreate.sh opencontainers || exit 3
./idb_backup opencontainers_temp opencontainers || exit 4
./grafana/influxdb_drop.sh opencontainers_temp
