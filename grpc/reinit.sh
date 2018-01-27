#!/bin/sh
./grafana/influxdb_recreate.sh grpc_temp || exit 1
GHA2DB_CMDDEBUG=1 GHA2DB_RESETIDB=1 GHA2DB_LOCAL=1 GHA2DB_PROJECT=grpc PG_DB=grpc IDB_DB=grpc_temp ./gha2db_sync || exit 2
./grafana/influxdb_recreate.sh grpc || exit 3
./idb_backup grpc_temp grpc || exit 4
./grafana/influxdb_drop.sh grpc_temp
