#!/bin/bash
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
./devel/drop_ts_tables.sh allcdf || exit 2
./devel/db.sh psql allcdf -c "delete from gha_vars" || exit 3
./devel/db.sh psql allcdf -c "delete from gha_computed" || exit 4
GHA2DB_PROJECT=allcdf PG_DB=allcdf GHA2DB_LOCAL=1 vars || exit 5
GHA2DB_SKIP_METRICS="projects_health" GHA2DB_EXCLUDE_VARS="projects_health_partial_html" GHA2DB_PROJECT=allcdf PG_DB=allcdf GHA2DB_CMDDEBUG=1 GHA2DB_RESETTSDB=1 GHA2DB_RESET_ES_RAW=1 GHA2DB_LOCAL=1 GHA2DB_SKIP_VARS=1 gha2db_sync || exit 6
