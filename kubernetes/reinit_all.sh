#!/bin/bash
./grafana/influxdb_recreate.sh gha_temp || exit 1
GHA2DB_PROJECT=kubernetes IDB_DB=gha_temp GHA2DB_LOCAL=1 GHA2DB_CMDDEBUG=1 GHA2DB_RESETIDB=1 PG_DB=gha ./gha2db_sync || exit 2
GHA2DB_LOCAL=1 GHA2DB_PROJECT=kubernetes IDB_DB=gha_temp ./idb_vars || exit 3
./grafana/influxdb_recreate.sh gha || exit 4
./idb_backup gha_temp gha
