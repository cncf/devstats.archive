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
set -o pipefail
> errors.txt
> run.log
GHA2DB_PROJECT=allcdf PG_DB=allcdf GHA2DB_LOCAL=1 GHA2DB_MGETC=y ./structure 2>>errors.txt | tee -a run.log || exit 1
./devel/db.sh psql allcdf -c "create extension if not exists pgcrypto" || exit 1
GHA2DB_INPUT_DBS="spinnaker,tekton,jenkins,jenkinsx" GHA2DB_OUTPUT_DB="allcdf" ./merge_dbs || exit 2
GHA2DB_PROJECT=allcdf PG_DB=allcdf GHA2DB_LOCAL=1 GHA2DB_MGETC=y GHA2DB_SKIPTABLE=1 GHA2DB_INDEX=1 ./structure 2>>errors.txt | tee -a run.log || exit 3
GHA2DB_PROJECT=allcdf PG_DB=allcdf ./shared/setup_repo_groups.sh 2>>errors.txt | tee -a run.log || exit 4
GHA2DB_PROJECT=allcdf PG_DB=allcdf ./shared/setup_scripts.sh 2>>errors.txt | tee -a run.log || exit 5
GHA2DB_PROJECT=allcdf PG_DB=allcdf ./shared/import_affs.sh 2>>errors.txt | tee -a run.log || exit 6
GHA2DB_PROJECT=allcdf PG_DB=allcdf ./shared/get_repos.sh 2>>errors.txt | tee -a run.log || exit 7
GHA2DB_PROJECT=allcdf PG_DB=allcdf GHA2DB_LOCAL=1 GHA2DB_EXCLUDE_VARS="projects_health_partial_html" ./vars || exit 8
./devel/ro_user_grants.sh allcdf || exit 10
./devel/psql_user_grants.sh devstats_team allcdf || exit 11
