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
GHA2DB_LOCAL=1 GHA2DB_PROJECT=opencontainers PG_DB=opencontainers IDB_DB=opencontainers ./runq scripts/clean_affiliations.sql
GHA2DB_LOCAL=1 GHA2DB_PROJECT=opencontainers PG_DB=opencontainers IDB_DB=opencontainers ./import_affs github_users.json || exit 1
exists=`echo 'show databases' | influx -host $IDB_HOST -username gha_admin -password $IDB_PASS | grep opencontainers`
if [ ! -z "$exists" ]
then
  GHA2DB_LOCAL=1 GHA2DB_PROJECT=opencontainers PG_DB=opencontainers IDB_DB=opencontainers ./idb_tags
fi
