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
GHA2DB_PROJECT=grpc IDB_DB=grpc PG_DB=grpc GHA2DB_LOCAL=1 ./structure 2>>errors.txt | tee -a run.log || exit 1
GHA2DB_PROJECT=grpc IDB_DB=grpc PG_DB=grpc GHA2DB_LOCAL=1 ./gha2db 2015-02-23 0 today now 'grpc' 2>>errors.txt | tee -a run.log || exit 2
GHA2DB_PROJECT=grpc IDB_DB=grpc PG_DB=grpc GHA2DB_LOCAL=1 GHA2DB_MGETC=y GHA2DB_SKIPTABLE=1 GHA2DB_INDEX=1 ./structure 2>>errors.txt | tee -a run.log || exit 3
./grpc/setup_repo_groups.sh 2>>errors.txt | tee -a run.log || exit 4
./grpc/import_affs.sh 2>>errors.txt | tee -a run.log || exit 5
./grpc/setup_scripts.sh 2>>errors.txt | tee -a run.log || exit 6
./grpc/get_repos.sh 2>>errors.txt | tee -a run.log || exit 7
echo "All done. You should run ./grpc/reinit.sh script now."
