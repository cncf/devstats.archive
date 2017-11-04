#!/bin/sh
./grafana/influxdb_recreate.sh prom_temp || exit 1
GHA2DB_CMDDEBUG=1 GHA2DB_RESETIDB=1 GHA2DB_LOCAL=1 GHA2DB_PROJECT=prometheus PG_DB=prometheus IDB_DB=prom_temp ./gha2db_sync || exit 1
./grafana/influxdb_recreate.sh prometheus || exit 1
./idb_backup prom_temp prometheus
