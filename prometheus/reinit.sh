#!/bin/bash
function finish {
    sync_unlock.sh
}
trap finish EXIT
sync_lock.sh || exit -1
./grafana/influxdb_recreate.sh prometheus_temp || exit 1
GHA2DB_CMDDEBUG=1 GHA2DB_RESETIDB=1 GHA2DB_LOCAL=1 GHA2DB_PROJECT=prometheus PG_DB=prometheus IDB_DB=prometheus_temp ./gha2db_sync || exit 2
GHA2DB_LOCAL=1 GHA2DB_PROJECT=prometheus IDB_DB=prometheus_temp ./idb_vars || exit 3
./grafana/influxdb_recreate.sh prometheus || exit 4
./idb_backup prometheus_temp prometheus || exit 5
./grafana/influxdb_drop.sh prometheus_temp
