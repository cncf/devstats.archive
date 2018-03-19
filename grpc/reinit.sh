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
./grafana/influxdb_recreate.sh grpc_temp || exit 1
GHA2DB_CMDDEBUG=1 GHA2DB_RESETIDB=1 GHA2DB_LOCAL=1 GHA2DB_PROJECT=grpc PG_DB=grpc IDB_DB=grpc_temp ./gha2db_sync || exit 2
GHA2DB_LOCAL=1 GHA2DB_PROJECT=grpc IDB_DB=grpc_temp ./idb_vars || exit 3
./grafana/influxdb_recreate.sh grpc || exit 4
IDB_DB_SRC=grpc_temp IDB_DB_DST=grpc ./idb_backup || exit 5
./grafana/influxdb_drop.sh grpc_temp
