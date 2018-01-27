#!/bin/sh
./grafana/influxdb_recreate.sh jaeger_temp || exit 1
GHA2DB_CMDDEBUG=1 GHA2DB_RESETIDB=1 GHA2DB_LOCAL=1 GHA2DB_PROJECT=jaeger PG_DB=jaeger IDB_DB=jaeger_temp ./gha2db_sync || exit 2
./grafana/influxdb_recreate.sh jaeger || exit 3
./idb_backup jaeger_temp jaeger || exit 4
./grafana/influxdb_drop.sh jaeger_temp
