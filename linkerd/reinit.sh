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
./grafana/influxdb_recreate.sh linkerd_temp || exit 1
GHA2DB_CMDDEBUG=1 GHA2DB_RESETIDB=1 GHA2DB_LOCAL=1 GHA2DB_PROJECT=linkerd PG_DB=linkerd IDB_DB=linkerd_temp ./gha2db_sync || exit 2
GHA2DB_LOCAL=1 GHA2DB_PROJECT=linkerd IDB_DB=linkerd_temp ./idb_vars || exit 3
./grafana/influxdb_recreate.sh linkerd || exit 4
./idb_backup linkerd_temp linkerd || exit 5
./grafana/influxdb_drop.sh linkerd_temp
