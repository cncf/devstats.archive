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
./grafana/influxdb_recreate.sh spire_temp || exit 1
GHA2DB_LOCAL=1 GHA2DB_PROJECT=spire IDB_DB=spire_temp ./idb_vars || exit 2
GHA2DB_CMDDEBUG=1 GHA2DB_RESETIDB=1 GHA2DB_LOCAL=1 GHA2DB_PROJECT=spire PG_DB=spire IDB_DB=spire_temp ./gha2db_sync || exit 3
./grafana/influxdb_recreate.sh spire || exit 4
IDB_DB_SRC=spire_temp IDB_DB_DST=spire ./idb_backup || exit 5
./grafana/influxdb_drop.sh spire_temp
