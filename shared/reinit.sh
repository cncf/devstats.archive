#!/bin/bash
# SKIPTEMP=1 skip regenerating data into temporary database and use current database directly
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
user=gha_admin
if [ ! -z "${PG_USER}" ]
then
  user="${PG_USER}"
fi
if [ ! -z "$SKIPTEMP" ]
then
  ./devel/drop_ts_tables.sh "$PG_DB" || exit 2
  PG_USER="${user}" ./devel/db.sh psql "$PG_DB" -c "delete from gha_vars" || exit 3
  PG_USER="${user}" ./devel/db.sh psql "$PG_DB" -c "delete from gha_computed" || exit 4
  GHA2DB_LOCAL=1 vars || exit 5
  GHA2DB_CMDDEBUG=1 GHA2DB_RESETTSDB=1 GHA2DB_RESET_ES_RAW=1 GHA2DB_LOCAL=1 gha2db_sync || exit 6
else
  db=$PG_DB
  tdb="${PG_DB}_temp"
  ./devel/db.sh pg_dump -Fc $db -f /tmp/$tdb.dump || exit 7
  mv /tmp/$tdb.dump . || exit 8
  ./devel/restore_db.sh $tdb || exit 9
  ./devel/drop_ts_tables.sh $tdb || exit 10
  PG_USER="${user}" ./devel/db.sh psql $tdb -c "delete from gha_vars" || exit 11
  PG_USER="${user}" ./devel/db.sh psql $tdb -c "delete from gha_computed" || exit 12
  GHA2DB_LOCAL=1 PG_DB=$tdb vars || exit 13
  GHA2DB_CMDDEBUG=1 GHA2DB_RESETTSDB=1 GHA2DB_RESET_ES_RAW=1 GHA2DB_LOCAL=1 PG_DB=$tdb gha2db_sync || exit 14
  ./devel/drop_psql_db.sh $db || exit 15
  ./devel/db.sh psql postgres -c "select pg_terminate_backend(pid) from pg_stat_activity where datname = '$tdb'" || exit 16
  ./devel/db.sh psql postgres -c "alter database \"$tdb\" rename to \"$db\"" || exit 17
  rm -f $tdb.dump || exit 18
fi
