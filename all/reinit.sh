#!/bin/bash
# HEALTH=1 (regenerate projects health metric)
if [ -z "$PG_PASS" ]
then
  echo "$0: you need to set PG_PASS env variable to use this script"
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

if [ ! -z "$SKIPTEMP" ]
then
  ./devel/drop_ts_tables.sh allprj || exit 2
  ./devel/db.sh psql allprj -c "delete from gha_vars" || exit 3
  ./devel/db.sh psql allprj -c "delete from gha_computed" || exit 4
  GHA2DB_PROJECT=all PG_DB=allprj GHA2DB_LOCAL=1 vars || exit 5
  GHA2DB_SKIP_METRICS="projects_health" GHA2DB_EXCLUDE_VARS="projects_health_partial_html" GHA2DB_PROJECT=all PG_DB=allprj GHA2DB_CMDDEBUG=1 GHA2DB_RESETTSDB=1 GHA2DB_RESET_ES_RAW=1 GHA2DB_LOCAL=1 GHA2DB_SKIP_VARS=1 gha2db_sync || exit 6
  if [ ! -z "$HEALTH" ]
  then
    ./devel/add_all_annotations.sh || exit 7
    GHA2DB_PROJECT=all PG_DB=allprj GHA2DB_LOCAL=1 GHA2DB_CMDDEBUG=1 GHA2DB_GHAPISKIP=1 GHA2DB_GETREPOSSKIP=1 GHA2DB_SKIPPDB=1 GHA2DB_RESETTSDB=1 GHA2DB_METRICS_YAML=metrics/all/health.yaml GHA2DB_TAGS_YAML=metrics/shared/empty.yaml GHA2DB_COLUMNS_YAML=metrics/shared/empty.yaml gha2db_sync || exit 8
    GHA2DB_PROJECT=all PG_DB=allprj GHA2DB_LOCAL=1 GHA2DB_VARS_FN_YAML="sync_vars.yaml" vars || exit 9
  fi
else
  ./devel/db.sh pg_dump -Fc allprj -f /tmp/allprj_temp.dump || exit 10
  mv /tmp/allprj_temp.dump . || exit 11
  ./devel/restore_db.sh allprj_temp || exit 12
  ./devel/drop_ts_tables.sh allprj_temp || exit 13
  ./devel/db.sh psql allprj_temp -c "delete from gha_vars" || exit 14
  ./devel/db.sh psql allprj_temp -c "delete from gha_computed" || exit 15
  GHA2DB_PROJECT=all PG_DB=allprj_temp GHA2DB_LOCAL=1 vars || exit 16
  GHA2DB_SKIP_METRICS="projects_health" GHA2DB_EXCLUDE_VARS="projects_health_partial_html" GHA2DB_PROJECT=all PG_DB=allprj_temp GHA2DB_CMDDEBUG=1 GHA2DB_RESETTSDB=1 GHA2DB_RESET_ES_RAW=1 GHA2DB_LOCAL=1 GHA2DB_SKIP_VARS=1 gha2db_sync || exit 17
  # HEALTH=1 unsupported in temp database mode
  ./devel/drop_psql_db.sh allprj || exit 18
  ./devel/db.sh psql postgres -c "select pg_terminate_backend(pid) from pg_stat_activity where datname = 'allprj_temp'" || exit 19
  ./devel/db.sh psql postgres -c "alter database \"allprj_temp\" rename to \"allprj\"" || exit 20
  rm -f allprj_temp.dump || exit 21
fi
