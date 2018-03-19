#!/bin/bash
function finish {
    sync_unlock.sh
}
if [ -z "$TRAP" ]
then
  sync_lock.sh || exit -1
  trap finish EXIT
  export TRAP=1
fi
./grafana/influxdb_recreate.sh containerd_temp || exit 1
GHA2DB_CMDDEBUG=1 GHA2DB_RESETIDB=1 GHA2DB_LOCAL=1 GHA2DB_PROJECT=containerd PG_DB=containerd IDB_DB=containerd_temp ./gha2db_sync || exit 2
GHA2DB_LOCAL=1 GHA2DB_PROJECT=containerd IDB_DB=containerd_temp ./idb_vars || exit 3
./grafana/influxdb_recreate.sh containerd || exit 4
IDB_DB_SRC=containerd_temp IDB_DB_DST=containerd ./idb_backup || exit 5
./grafana/influxdb_drop.sh containerd_temp
