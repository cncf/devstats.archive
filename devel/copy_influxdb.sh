#!/bin/bash
if [ -z "$PROJDB" ]
then
  echo "$0: You need to set PROJDB environment variables to run this script"
  exit 1
fi
if [ -z "$IDB_HOST_SRC" ]
then
  IDB_HOST_SRC=cncftest.io
fi
function finish {
    sync_unlock.sh
}
if [ -z "$TRAP" ]
then
  sync_lock.sh || exit -1
  trap finish EXIT
  export TRAP=1
fi
echo "fetching $PROJDB database from cncftest.io (into ${PROJDB}_temp database)"
./grafana/influxdb_recreate.sh "${PROJDB}_temp" || exit 2
IDB_USER_SRC=ro_user IDB_DB_SRC="$PROJDB" IDB_DB_DST="${PROJDB}_temp" ./idb_backup || exit 3
echo "copying ${PROJDB}_temp database to $PROJDB"
./grafana/influxdb_recreate.sh temp || exit 4
unset IDB_PASS_SRC
IDB_DB_SRC="${PROJDB}_temp" IDB_DB_DST="$PROJDB" ./idb_backup || exit 5
./grafana/influxdb_drop.sh "${PROJDB}_temp" || exit 6
