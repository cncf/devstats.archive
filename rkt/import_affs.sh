#!/bin/bash
function finish {
    sync_unlock.sh
}
trap finish EXIT
sync_lock.sh || exit -1
GHA2DB_LOCAL=1 GHA2DB_PROJECT=rkt PG_DB=rkt IDB_DB=rkt ./runq scripts/clean_affiliations.sql
GHA2DB_LOCAL=1 GHA2DB_PROJECT=rkt PG_DB=rkt IDB_DB=rkt ./import_affs github_users.json || exit 1
GHA2DB_LOCAL=1 GHA2DB_PROJECT=rkt PG_DB=rkt IDB_DB=rkt ./idb_tags
