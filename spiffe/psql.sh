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
GHA2DB_PROJECT=spiffe IDB_DB=spiffe PG_DB=spiffe GHA2DB_LOCAL=1 ./structure 2>>errors.txt | tee -a run.log || exit 1
GHA2DB_EXCLUDE_REPOS='spiffe/spire' GHA2DB_PROJECT=spiffe IDB_DB=spiffe PG_DB=spiffe GHA2DB_LOCAL=1 ./gha2db 2017-08-23 0 today now 'spiffe' 2>>errors.txt | tee -a run.log || exit 2
GHA2DB_PROJECT=spiffe IDB_DB=spiffe PG_DB=spiffe GHA2DB_LOCAL=1 GHA2DB_MGETC=y GHA2DB_SKIPTABLE=1 GHA2DB_INDEX=1 ./structure 2>>errors.txt | tee -a run.log || exit 3
./spiffe/setup_repo_groups.sh 2>>errors.txt | tee -a run.log || exit 4
./spiffe/import_affs.sh 2>>errors.txt | tee -a run.log || exit 5
./spiffe/setup_scripts.sh 2>>errors.txt | tee -a run.log || exit 6
GHA2DB_PROJECT=spiffe PG_DB=spiffe ./shared/get_repos.sh 2>>errors.txt | tee -a run.log || exit 7
GHA2DB_PROJECT=spiffe PG_DB=spiffe GHA2DB_LOCAL=1 ./pdb_vars || exit 8
./devel/ro_user_grants.sh spiffe || exit 9
echo "All done. You should run ./spiffe/reinit.sh script now."
