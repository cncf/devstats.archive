#!/bin/sh
./grafana/influxdb_recreate.sh vitess_temp || exit 1
GHA2DB_CMDDEBUG=1 GHA2DB_RESETIDB=1 GHA2DB_LOCAL=1 GHA2DB_PROJECT=vitess PG_DB=vitess IDB_DB=vitess_temp ./gha2db_sync || exit 2
./grafana/influxdb_recreate.sh vitess || exit 3
./idb_backup vitess_temp vitess || exit 4
./grafana/influxdb_drop.sh vitess_temp
