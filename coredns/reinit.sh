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
./grafana/influxdb_recreate.sh coredns_temp || exit 1
GHA2DB_CMDDEBUG=1 GHA2DB_RESETIDB=1 GHA2DB_LOCAL=1 GHA2DB_PROJECT=coredns PG_DB=coredns IDB_DB=coredns_temp ./gha2db_sync || exit 2
GHA2DB_LOCAL=1 GHA2DB_PROJECT=coredns IDB_DB=coredns_temp ./idb_vars || exit 3
./grafana/influxdb_recreate.sh coredns || exit 4
IDB_DB_SRC=coredns_temp IDB_DB_DST=coredns ./idb_backup || exit 5
./grafana/influxdb_drop.sh coredns_temp
