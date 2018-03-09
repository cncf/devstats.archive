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
./grafana/influxdb_recreate.sh vitess_temp || exit 1
GHA2DB_LOCAL=1 GHA2DB_PROJECT=vitess IDB_DB=vitess_temp ./idb_vars || exit 2
GHA2DB_CMDDEBUG=1 GHA2DB_RESETIDB=1 GHA2DB_LOCAL=1 GHA2DB_PROJECT=vitess PG_DB=vitess IDB_DB=vitess_temp ./gha2db_sync || exit 3
./grafana/influxdb_recreate.sh vitess || exit 4
./idb_backup vitess_temp vitess || exit 5
./grafana/influxdb_drop.sh vitess_temp
