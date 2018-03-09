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
./grafana/influxdb_recreate.sh gha || exit 1
GHA2DB_PROJECT=kubernetes GHA2DB_LOCAL=1 GHA2DB_CMDDEBUG=1 GHA2DB_RESETIDB=1 PG_DB=gha IDB_DB=gha ./gha2db_sync || exit 2
GHA2DB_LOCAL=1 GHA2DB_PROJECT=kubernetes IDB_DB=gha ./idb_vars || exit 3
