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
GHA2DB_LOCAL=1 GHA2DB_PROJECT=notary PG_DB=notary IDB_DB=notary ./runq scripts/clean_affiliations.sql
GHA2DB_LOCAL=1 GHA2DB_PROJECT=notary PG_DB=notary IDB_DB=notary ./import_affs github_users.json || exit 1
exists=`echo 'show databases' | influx -host $IDB_HOST -username gha_admin -password $IDB_PASS | grep notary`
if [ -z "$exists" ]
then
  ./grafana/influxdb_recreate.sh notary || exit 2
fi
GHA2DB_LOCAL=1 GHA2DB_PROJECT=notary PG_DB=notary IDB_DB=notary ./idb_tags
