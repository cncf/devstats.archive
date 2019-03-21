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
proj=$GHA2DB_PROJECT
./devel/drop_tsdb_affs_tables.sh "$PG_DB"
# GHA2DB_COLUMNS_YAML=metrics/$GHA2DB_PROJECT/columns_affs.yaml GHA2DB_LOCAL=1 ./columns
GHA2DB_CMDDEBUG=1 GHA2DB_LOCAL=1 GHA2DB_RESET_ES_RAW=1 GHA2DB_RESETTSDB=1 GHA2DB_COLUMNS_YAML=./metrics/$proj/columns_affs.yaml GHA2DB_METRICS_YAML=./metrics/$proj/metrics_affs.yaml GHA2DB_TAGS_YAML=./metrics/$proj/tags_affs.yaml gha2db_sync
