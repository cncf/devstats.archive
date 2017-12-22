#!/bin/sh
./grafana/influxdb_recreate.sh cncf_temp || exit 1
GHA2DB_CMDDEBUG=1 GHA2DB_RESETIDB=1 GHA2DB_LOCAL=1 GHA2DB_PROJECT=cncf PG_DB=cncf IDB_DB=cncf_temp ./gha2db_sync || exit 1
./grafana/influxdb_recreate.sh cncf || exit 1
./idb_backup cncf_temp cncf
