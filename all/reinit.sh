#!/bin/sh
./grafana/influxdb_recreate.sh allprj_temp || exit 1
GHA2DB_LOCAL=1 GHA2DB_PROJECT=all IDB_DB=allprj_temp ./idb_vars || exit 3
GHA2DB_CMDDEBUG=1 GHA2DB_RESETIDB=1 GHA2DB_LOCAL=1 GHA2DB_PROJECT=all PG_DB=allprj IDB_DB=allprj_temp ./gha2db_sync || exit 2
./grafana/influxdb_recreate.sh allprj || exit 4
./idb_backup allprj_temp allprj || exit 5
./grafana/influxdb_drop.sh allprj_temp
