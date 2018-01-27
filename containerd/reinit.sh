#!/bin/sh
./grafana/influxdb_recreate.sh containerd_temp || exit 1
GHA2DB_CMDDEBUG=1 GHA2DB_RESETIDB=1 GHA2DB_LOCAL=1 GHA2DB_PROJECT=containerd PG_DB=containerd IDB_DB=containerd_temp ./gha2db_sync || exit 2
./grafana/influxdb_recreate.sh containerd || exit 3
./idb_backup containerd_temp containerd || exit 4
./grafana/influxdb_drop.sh containerd_temp
