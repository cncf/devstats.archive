#!/bin/sh
./grafana/influxdb_recreate.sh linkerd_temp || exit 1
GHA2DB_CMDDEBUG=1 GHA2DB_RESETIDB=1 GHA2DB_LOCAL=1 GHA2DB_PROJECT=linkerd PG_DB=linkerd IDB_DB=linkerd_temp ./gha2db_sync || exit 1
./grafana/influxdb_recreate.sh linkerd || exit 1
./idb_backup linkerd_temp linkerd
