#!/bin/sh
./grafana/influxdb_recreate.sh opentracing_temp || exit 1
GHA2DB_CMDDEBUG=1 GHA2DB_RESETIDB=1 GHA2DB_LOCAL=1 GHA2DB_PROJECT=opentracing GHA2DB_STARTDT=2015-11-26 PG_DB=opentracing IDB_DB=opentracing_temp ./gha2db_sync || exit 1
./grafana/influxdb_recreate.sh opentracing || exit 1
./idb_backup opentracing_temp opentracing
