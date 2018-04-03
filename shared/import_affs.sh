#!/bin/bash
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
GHA2DB_LOCAL=1 ./runq scripts/clean_affiliations.sql || exit 1
GHA2DB_LOCAL=1 ./import_affs github_users.json || exit 2
if [ -z "$IDB_HOST" ]
then
  exists=`echo 'show databases' | influx -username gha_admin -password $IDB_PASS | grep gha`
else
  exists=`echo 'show databases' | influx -host $IDB_HOST -username gha_admin -password $IDB_PASS | grep gha`
fi
if [ ! -z "$exists" ]
then
  GHA2DB_LOCAL=1 ./idb_tags
fi
