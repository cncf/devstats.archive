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
./grafana/influxdb_recreate.sh nats_temp || exit 1
GHA2DB_LOCAL=1 GHA2DB_PROJECT=nats IDB_DB=nats_temp ./idb_vars || exit 2
GHA2DB_CMDDEBUG=1 GHA2DB_RESETIDB=1 GHA2DB_LOCAL=1 GHA2DB_PROJECT=nats PG_DB=nats IDB_DB=nats_temp ./gha2db_sync || exit 3
./grafana/influxdb_recreate.sh nats || exit 4
./idb_backup nats_temp nats || exit 5
./grafana/influxdb_drop.sh nats_temp
