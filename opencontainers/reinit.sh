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
./grafana/influxdb_recreate.sh opencontainers_temp || exit 1
GHA2DB_CMDDEBUG=1 GHA2DB_RESETIDB=1 GHA2DB_LOCAL=1 GHA2DB_PROJECT=opencontainers PG_DB=opencontainers IDB_DB=opencontainers_temp ./gha2db_sync || exit 2
GHA2DB_LOCAL=1 GHA2DB_PROJECT=opencontainers IDB_DB=opencontainers_temp ./idb_vars || exit 3
./grafana/influxdb_recreate.sh opencontainers || exit 4
./idb_backup opencontainers_temp opencontainers || exit 5
./grafana/influxdb_drop.sh opencontainers_temp
