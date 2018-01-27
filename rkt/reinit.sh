#!/bin/sh
./grafana/influxdb_recreate.sh rkt_temp || exit 1
GHA2DB_CMDDEBUG=1 GHA2DB_RESETIDB=1 GHA2DB_LOCAL=1 GHA2DB_PROJECT=rkt PG_DB=rkt IDB_DB=rkt_temp ./gha2db_sync || exit 2
./grafana/influxdb_recreate.sh rkt || exit 3
./idb_backup rkt_temp rkt || exit 4
./grafana/influxdb_drop.sh rkt_temp
