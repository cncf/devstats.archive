#!/bin/bash
# HEALTH=1 - regenerate health metric
if [ -z "${PG_DB}" ]
then
  echo "You need to set PG_DB environment variable to run this script"
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
if [ -z "$HEALTH" ]
then
  if [ -z "$GHA2DB_METRICS_YAML" ]
  then
    export GHA2DB_METRICS_YAML=devel/test_metrics.yaml
  fi
  if [ -z "$GHA2DB_TAGS_YAML" ]
  then
    export GHA2DB_TAGS_YAML=devel/test_tags.yaml
  fi
  if [ -z "$GHA2DB_COLUMNS_YAML" ]
  then
    export GHA2DB_COLUMNS_YAML=devel/test_columns.yaml
  fi
  GHA2DB_ENABLE_METRICS_DROP=1 GHA2DB_CMDDEBUG=1 GHA2DB_GHAPISKIP=1 GHA2DB_GETREPOSSKIP=1 GHA2DB_SKIPPDB=1 GHA2DB_RESETTSDB=1 GHA2DB_LOCAL=1 gha2db_sync
else
  if ( [ "$PG_DB" = "allprj" ] || [ "$PG_DB" = "allcdf" ] || [ "$PG_DB" = "graphql" ] )
  then
    GHA2DB_ENABLE_METRICS_DROP=1 GHA2DB_CMDDEBUG=1 GHA2DB_GHAPISKIP=1 GHA2DB_GETREPOSSKIP=1 GHA2DB_SKIPPDB=1 GHA2DB_RESETTSDB=1 GHA2DB_METRICS_YAML=devel/test_metrics_health.yaml GHA2DB_LOCAL=1 gha2db_sync
  else
    echo "$0 HEALTH mode only allowed for allprj, allcdf and graphql databases, current database is $PG_DB"
    exit 1
  fi
fi
