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
GHA2DB_PROJECT=rkt PG_DB=rkt GHA2DB_LOCAL=1 ./structure 2>>errors.txt | tee -a run.log || exit 1
sudo -u postgres psql rkt -c "create extension if not exists pgcrypto" || exit 1
GHA2DB_PROJECT=rkt PG_DB=rkt GHA2DB_LOCAL=1 ./gha2db 2017-04-04 0 today now 'rkt' 2>>errors.txt | tee -a run.log || exit 2
GHA2DB_PROJECT=rkt PG_DB=rkt GHA2DB_LOCAL=1 GHA2DB_EXACT=1 ./gha2db 2015-01-01 0 2017-04-07 0 'coreos/rkt,coreos/rocket,rktproject/rkt' 2>>errors.txt | tee -a run.log || exit 3
GHA2DB_PROJECT=rkt PG_DB=rkt GHA2DB_LOCAL=1 GHA2DB_EXACT=1 GHA2DB_OLDFMT=1 ./gha2db 2014-11-26 0 2014-12-31 23 'rocket' 2>>errors.txt | tee -a run.log || exit 4
GHA2DB_PROJECT=rkt PG_DB=rkt GHA2DB_LOCAL=1 GHA2DB_MGETC=y GHA2DB_SKIPTABLE=1 GHA2DB_INDEX=1 ./structure 2>>errors.txt | tee -a run.log || exit 5
GHA2DB_PROJECT=rkt PG_DB=rkt ./shared/setup_repo_groups.sh 2>>errors.txt | tee -a run.log || exit 6
GHA2DB_PROJECT=rkt PG_DB=rkt ./shared/import_affs.sh 2>>errors.txt | tee -a run.log || exit 7
GHA2DB_PROJECT=rkt PG_DB=rkt ./shared/setup_scripts.sh 2>>errors.txt | tee -a run.log || exit 8
GHA2DB_PROJECT=rkt PG_DB=rkt ./shared/get_repos.sh 2>>errors.txt | tee -a run.log || exit 9
GHA2DB_PROJECT=rkt PG_DB=rkt GHA2DB_LOCAL=1 ./vars || exit 10
./devel/ro_user_grants.sh rkt || exit 11
./devel/psql_user_grants.sh devstats_team rkt || exit 12
