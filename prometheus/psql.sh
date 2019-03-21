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
GHA2DB_PROJECT=prometheus PG_DB=prometheus GHA2DB_LOCAL=1 structure 2>>errors.txt | tee -a run.log || exit 1
./devel/db.sh psql prometheus -c "create extension if not exists pgcrypto" || exit 1
GHA2DB_PROJECT=prometheus PG_DB=prometheus GHA2DB_LOCAL=1 gha2db 2015-01-01 0 today now 'prometheus' 2>>errors.txt | tee -a run.log || exit 2
GHA2DB_PROJECT=prometheus PG_DB=prometheus GHA2DB_LOCAL=1 GHA2DB_OLDFMT=1 GHA2DB_EXACT=1 gha2db 2014-01-06 0 2014-12-31 23 'prometheus/prometheus' 2>>errors.txt | tee -a run.log || exit 3
GHA2DB_PROJECT=prometheus PG_DB=prometheus GHA2DB_LOCAL=1 GHA2DB_MGETC=y GHA2DB_SKIPTABLE=1 GHA2DB_INDEX=1 structure 2>>errors.txt | tee -a run.log || exit 4
GHA2DB_PROJECT=prometheus PG_DB=prometheus ./shared/setup_repo_groups.sh 2>>errors.txt | tee -a run.log || exit 5
GHA2DB_PROJECT=prometheus PG_DB=prometheus ./shared/setup_scripts.sh 2>>errors.txt | tee -a run.log || exit 6
GHA2DB_PROJECT=prometheus PG_DB=prometheus ./shared/import_affs.sh 2>>errors.txt | tee -a run.log || exit 7
GHA2DB_PROJECT=prometheus PG_DB=prometheus ./shared/get_repos.sh 2>>errors.txt | tee -a run.log || exit 8
GHA2DB_PROJECT=prometheus PG_DB=prometheus GHA2DB_LOCAL=1 ./vars || exit 9
./devel/ro_user_grants.sh prometheus || exit 10
./devel/psql_user_grants.sh devstats_team prometheus || exit 11
