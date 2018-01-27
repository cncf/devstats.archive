#!/bin/sh
./grafana/influxdb_recreate.sh notary_temp || exit 1
GHA2DB_CMDDEBUG=1 GHA2DB_RESETIDB=1 GHA2DB_LOCAL=1 GHA2DB_PROJECT=notary PG_DB=notary IDB_DB=notary_temp ./gha2db_sync || exit 2
./grafana/influxdb_recreate.sh notary || exit 3
./idb_backup notary_temp notary || exit 4
./grafana/influxdb_drop.sh notary_temp
