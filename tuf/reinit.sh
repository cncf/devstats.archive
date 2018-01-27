#!/bin/sh
./grafana/influxdb_recreate.sh tuf_temp || exit 1
GHA2DB_CMDDEBUG=1 GHA2DB_RESETIDB=1 GHA2DB_LOCAL=1 GHA2DB_PROJECT=tuf PG_DB=tuf IDB_DB=tuf_temp ./gha2db_sync || exit 2
./grafana/influxdb_recreate.sh tuf || exit 3
./idb_backup tuf_temp tuf || exit 4
./grafana/influxdb_drop.sh tuf_temp
