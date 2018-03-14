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
GHA2DB_PROJECT=rook IDB_DB=rook PG_DB=rook GHA2DB_LOCAL=1 ./structure 2>>errors.txt | tee -a run.log || exit 1
GHA2DB_PROJECT=rook IDB_DB=rook PG_DB=rook GHA2DB_LOCAL=1 ./gha2db 2016-11-07 0 today now 'rook' 2>>errors.txt | tee -a run.log || exit 2
GHA2DB_PROJECT=rook IDB_DB=rook PG_DB=rook GHA2DB_LOCAL=1 GHA2DB_MGETC=y GHA2DB_SKIPTABLE=1 GHA2DB_INDEX=1 ./structure 2>>errors.txt | tee -a run.log || exit 3
./rook/setup_repo_groups.sh 2>>errors.txt | tee -a run.log || exit 4
./rook/import_affs.sh 2>>errors.txt | tee -a run.log || exit 5
./rook/setup_scripts.sh 2>>errors.txt | tee -a run.log || exit 6
./rook/get_repos.sh 2>>errors.txt | tee -a run.log || exit 7
GHA2DB_PROJECT=rook PG_DB=rook GHA2DB_LOCAL=1 ./pdb_vars || exit 8
echo "All done. You should run ./rook/reinit.sh script now."
