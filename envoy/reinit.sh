#!/bin/sh
./grafana/influxdb_recreate.sh envoy_temp || exit 1
GHA2DB_CMDDEBUG=1 GHA2DB_RESETIDB=1 GHA2DB_LOCAL=1 GHA2DB_PROJECT=envoy PG_DB=envoy IDB_DB=envoy_temp ./gha2db_sync || exit 1
./grafana/influxdb_recreate.sh envoy || exit 1
./idb_backup envoy_temp envoy
