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
./grafana/influxdb_recreate.sh cncf_temp || exit 1
GHA2DB_CMDDEBUG=1 GHA2DB_RESETIDB=1 GHA2DB_LOCAL=1 GHA2DB_PROJECT=cncf PG_DB=cncf IDB_DB=cncf_temp ./gha2db_sync || exit 2
GHA2DB_LOCAL=1 GHA2DB_PROJECT=cncf IDB_DB=cncf_temp ./idb_vars || exit 3
./grafana/influxdb_recreate.sh cncf || exit 4
IDB_DB_SRC=cncf_temp IDB_DB_DST=cncf ./idb_backup || exit 5
./grafana/influxdb_drop.sh cncf_temp
