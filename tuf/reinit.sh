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
./grafana/influxdb_recreate.sh tuf_temp || exit 1
GHA2DB_CMDDEBUG=1 GHA2DB_RESETIDB=1 GHA2DB_LOCAL=1 GHA2DB_PROJECT=tuf PG_DB=tuf IDB_DB=tuf_temp ./gha2db_sync || exit 2
GHA2DB_LOCAL=1 GHA2DB_PROJECT=tuf IDB_DB=tuf_temp ./idb_vars || exit 3
./grafana/influxdb_recreate.sh tuf || exit 4
./idb_backup tuf_temp tuf || exit 5
./grafana/influxdb_drop.sh tuf_temp
