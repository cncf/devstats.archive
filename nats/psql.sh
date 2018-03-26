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
GHA2DB_PROJECT=nats IDB_DB=nats PG_DB=nats GHA2DB_LOCAL=1 ./structure 2>>errors.txt | tee -a run.log || exit 1
GHA2DB_PROJECT=nats IDB_DB=nats PG_DB=nats GHA2DB_LOCAL=1 ./gha2db 2015-01-01 0 today now 'nats-io,apcera/nats,apcera/gnatsd' 2>>errors.txt | tee -a run.log || exit 2
GHA2DB_PROJECT=nats IDB_DB=nats PG_DB=nats GHA2DB_LOCAL=1 GHA2DB_EXACT=1 GHA2DB_OLDFMT=1 ./gha2db 2014-01-02 0 2014-03-02 16 'nats-io,apcera/nats,apcera/gnatsd' 2>>errors.txt | tee -a run.log || exit 3
GHA2DB_PROJECT=nats IDB_DB=nats PG_DB=nats GHA2DB_LOCAL=1 GHA2DB_EXACT=1 GHA2DB_OLDFMT=1 ./gha2db 2014-03-02 18 2014-12-31 23 'nats-io,apcera/nats,apcera/gnatsd' 2>>errors.txt | tee -a run.log || exit 3
GHA2DB_PROJECT=nats IDB_DB=nats PG_DB=nats GHA2DB_LOCAL=1 GHA2DB_MGETC=y GHA2DB_SKIPTABLE=1 GHA2DB_INDEX=1 ./structure 2>>errors.txt | tee -a run.log || exit 4
./nats/setup_repo_groups.sh 2>>errors.txt | tee -a run.log || exit 5
./nats/import_affs.sh 2>>errors.txt | tee -a run.log || exit 6
./nats/setup_scripts.sh 2>>errors.txt | tee -a run.log || exit 7
./nats/get_repos.sh 2>>errors.txt | tee -a run.log || exit 8
GHA2DB_PROJECT=nats PG_DB=nats GHA2DB_LOCAL=1 ./pdb_vars || exit 9
./devel/ro_user_grants.sh nats || exit 10
echo "All done. You should run ./nats/reinit.sh script now."
