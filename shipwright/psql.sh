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
GHA2DB_PROJECT=shipwright PG_DB=shipwright GHA2DB_LOCAL=1 structure 2>>errors.txt | tee -a run.log || exit 1
./devel/db.sh psql shipwright -c "create extension if not exists pgcrypto" || exit 1
GHA2DB_PROJECT=shipwright PG_DB=shipwright GHA2DB_LOCAL=1 gha2db 2020-02-16 0 today now "shipwright-io,redhat-developer/build,redhat-developer/buildv2,redhat-developer/buildv2-operator" 2>>errors.txt | tee -a run.log || exit 2
GHA2DB_PROJECT=shipwright PG_DB=shipwright GHA2DB_LOCAL=1 GHA2DB_MGETC=y GHA2DB_SKIPTABLE=1 GHA2DB_INDEX=1 structure 2>>errors.txt | tee -a run.log || exit 4
GHA2DB_PROJECT=shipwright PG_DB=shipwright ./shared/setup_repo_groups.sh 2>>errors.txt | tee -a run.log || exit 5
GHA2DB_PROJECT=shipwright PG_DB=shipwright ./shared/import_affs.sh 2>>errors.txt | tee -a run.log || exit 6
GHA2DB_PROJECT=shipwright PG_DB=shipwright ./shared/setup_scripts.sh 2>>errors.txt | tee -a run.log || exit 7
GHA2DB_PROJECT=shipwright PG_DB=shipwright ./shared/get_repos.sh 2>>errors.txt | tee -a run.log || exit 8
GHA2DB_PROJECT=shipwright PG_DB=shipwright GHA2DB_LOCAL=1 vars || exit 9
./devel/ro_user_grants.sh shipwright || exit 10
./devel/psql_user_grants.sh devstats_team shipwright || exit 11
