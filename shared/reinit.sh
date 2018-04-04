#!/bin/bash
# SKIPTEMP=1 will skip regenerating into temp database and then copying from temp to dest, it will regenerate on dest directly then.
if ( [ -z "$GHA2DB_PROJECT" ] || [ -z "$IDB_DB" ] || [ -z "$IDB_PASS" ] || [ -z "$PG_DB" ] || [ -z "$PG_PASS" ] )
then
  echo "$0: you need to set GHA2DB_PROJECT, IDB_DB, IDB_PASS, PG_DB, PG_PASS env variables to use this script"
  exit 1
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
db=$IDB_DB
if [ -z "$SKIPTEMP" ]
then
  db_temp="${db}_temp"
  ./grafana/influxdb_recreate.sh "$db_temp" || exit 1
  GHA2DB_LOCAL=1 IDB_DB="$db_temp" ./idb_vars || exit 2
  GHA2DB_CMDDEBUG=1 GHA2DB_RESETIDB=1 GHA2DB_LOCAL=1 IDB_DB="$db_temp" ./gha2db_sync || exit 3
  ./grafana/influxdb_recreate.sh "$db" || exit 4
  IDB_DB_SRC="$db_temp" IDB_DB_DST="$db" ./idb_backup || exit 5
  ./grafana/influxdb_drop.sh "$db_temp"
else
  ./grafana/influxdb_recreate.sh "$db" || exit 6
  GHA2DB_LOCAL=1 IDB_DB="$db" ./idb_vars || exit 7
  GHA2DB_CMDDEBUG=1 GHA2DB_RESETIDB=1 GHA2DB_LOCAL=1 IDB_DB="$db" ./gha2db_sync || exit 8
fi
