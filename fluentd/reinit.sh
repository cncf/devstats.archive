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
./grafana/influxdb_recreate.sh fluentd_temp || exit 1
GHA2DB_CMDDEBUG=1 GHA2DB_RESETIDB=1 GHA2DB_LOCAL=1 GHA2DB_PROJECT=fluentd PG_DB=fluentd IDB_DB=fluentd_temp ./gha2db_sync || exit 2
GHA2DB_LOCAL=1 GHA2DB_PROJECT=fluentd IDB_DB=fluentd_temp ./idb_vars || exit 3
./grafana/influxdb_recreate.sh fluentd || exit 4
IDB_DB_SRC=fluentd_temp IDB_DB_DST=fluentd ./idb_backup || exit 5
./grafana/influxdb_drop.sh fluentd_temp
