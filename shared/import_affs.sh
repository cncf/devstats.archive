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
GHA2DB_LOCAL=1 ./runq scripts/clean_affiliations.sql || exit 1
GHA2DB_LOCAL=1 ./import_affs github_users.json || exit 2
GHA2DB_TAGS_YAML=metrics/$GHA2DB_PROJECT/tags_affs.yaml GHA2DB_LOCAL=1 ./tags
