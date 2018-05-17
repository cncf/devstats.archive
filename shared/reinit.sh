#!/bin/bash
if ( [ -z "$GHA2DB_PROJECT" ] || [ -z "$PG_DB" ] || [ -z "$PG_PASS" ] )
then
  echo "$0: you need to set GHA2DB_PROJECT, PG_DB, PG_PASS env variables to use this script"
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
./devel/drop_ts_tables.sh "$PG_DB" || exit 2
sudo -u postgres psql "$PG_DB" -c "delete from gha_vars" || exit 3
GHA2DB_LOCAL=1 ./vars || exit 4
GHA2DB_CMDDEBUG=1 GHA2DB_RESETTSDB=1 GHA2DB_LOCAL=1 ./gha2db_sync || exit 5
