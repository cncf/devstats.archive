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
GHA2DB_LOCAL=1 GHA2DB_PROJECT=grpc PG_DB=grpc IDB_DB=grpc ./runq scripts/clean_affiliations.sql
GHA2DB_LOCAL=1 GHA2DB_PROJECT=grpc PG_DB=grpc IDB_DB=grpc ./import_affs github_users.json || exit 1
GHA2DB_LOCAL=1 GHA2DB_PROJECT=grpc PG_DB=grpc IDB_DB=grpc ./idb_tags
