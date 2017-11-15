#!/bin/sh
./grafana/influxdb_recreate.sh prometheus_temp || exit 1
GHA2DB_CMDDEBUG=1 GHA2DB_RESETIDB=1 GHA2DB_LOCAL=1 GHA2DB_PROJECT=prometheus GHA2DB_STARTDT=2014-03-03 PG_DB=prometheus IDB_DB=prometheus_temp ./gha2db_sync || exit 1
./grafana/influxdb_recreate.sh prometheus || exit 1
./idb_backup prometheus_temp prometheus
