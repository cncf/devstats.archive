#!/bin/sh
./grafana/influxdb_recreate.sh opentracing_temp || exit 1
GHA2DB_CMDDEBUG=1 GHA2DB_RESETIDB=1 GHA2DB_LOCAL=1 GHA2DB_PROJECT=opentracing PG_DB=opentracing IDB_DB=opentracing_temp ./gha2db_sync || exit 2
./grafana/influxdb_recreate.sh opentracing || exit 3
./idb_backup opentracing_temp opentracing || exit 4
./grafana/influxdb_drop.sh opnetracing_temp
