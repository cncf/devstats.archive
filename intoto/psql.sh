#!/bin/bash
set -o pipefail
function finish {
    sync_unlock.sh
}
if [ -z "$TRAP" ]
then
  sync_lock.sh || exit -1
  trap finish EXIT
  export TRAP=1
fi
> errors.txt
> run.log
GHA2DB_PROJECT=intoto PG_DB=intoto GHA2DB_LOCAL=1 structure 2>>errors.txt | tee -a run.log || exit 1
./devel/db.sh psql intoto -c "create extension if not exists pgcrypto" || exit 1
GHA2DB_PROJECT=intoto PG_DB=intoto GHA2DB_LOCAL=1 gha2db 2016-10-18 0 today now 'in-toto' 2>>errors.txt | tee -a run.log || exit 2
GHA2DB_PROJECT=intoto PG_DB=intoto GHA2DB_LOCAL=1 GHA2DB_MGETC=y GHA2DB_SKIPTABLE=1 GHA2DB_INDEX=1 structure 2>>errors.txt | tee -a run.log || exit 3
GHA2DB_PROJECT=intoto PG_DB=intoto ./shared/setup_repo_groups.sh 2>>errors.txt | tee -a run.log || exit 4
GHA2DB_PROJECT=intoto PG_DB=intoto ./shared/import_affs.sh 2>>errors.txt | tee -a run.log || exit 5
GHA2DB_PROJECT=intoto PG_DB=intoto ./shared/setup_scripts.sh 2>>errors.txt | tee -a run.log || exit 6
GHA2DB_PROJECT=intoto PG_DB=intoto ./shared/get_repos.sh 2>>errors.txt | tee -a run.log || exit 7
GHA2DB_PROJECT=intoto PG_DB=intoto GHA2DB_LOCAL=1 vars || exit 8
./devel/ro_user_grants.sh intoto || exit 9
./devel/psql_user_grants.sh devstats_team intoto || exit 10
