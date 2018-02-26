#!/bin/sh
./grafana/influxdb_recreate.sh coredns_temp || exit 1
GHA2DB_CMDDEBUG=1 GHA2DB_RESETIDB=1 GHA2DB_LOCAL=1 GHA2DB_PROJECT=coredns PG_DB=coredns IDB_DB=coredns_temp ./gha2db_sync || exit 2
GHA2DB_LOCAL=1 GHA2DB_PROJECT=coredns IDB_DB=coredns_temp ./idb_vars || exit 3
./grafana/influxdb_recreate.sh coredns || exit 4
./idb_backup coredns_temp coredns || exit 5
./grafana/influxdb_drop.sh coredns_temp
