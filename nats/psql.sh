#!/bin/bash
function finish {
    sync_unlock.sh
}
trap finish EXIT
sync_lock.sh || exit -1
set -o pipefail
> errors.txt
> run.log
GHA2DB_PROJECT=nats IDB_DB=nats PG_DB=nats GHA2DB_LOCAL=1 ./structure 2>>errors.txt | tee -a run.log || exit 1
GHA2DB_PROJECT=nats IDB_DB=nats PG_DB=nats GHA2DB_LOCAL=1 ./gha2db 2015-01-01 0 today now 'nats-io,apcera/nats,apcera/gnatsd' 2>>errors.txt | tee -a run.log || exit 2
GHA2DB_PROJECT=nats IDB_DB=nats PG_DB=nats GHA2DB_LOCAL=1 GHA2DB_EXACT=1 GHA2DB_OLDFMT=1 ./gha2db 2014-01-02 0 2014-12-31 23 'nats-io,apcera/nats,apcera/gnatsd' 2>>errors.txt | tee -a run.log || exit 3
GHA2DB_PROJECT=nats IDB_DB=nats PG_DB=nats GHA2DB_LOCAL=1 GHA2DB_MGETC=y GHA2DB_SKIPTABLE=1 GHA2DB_INDEX=1 ./structure 2>>errors.txt | tee -a run.log || exit 4
./grafana/influxdb_recreate.sh nats
./nats/setup_repo_groups.sh 2>>errors.txt | tee -a run.log || exit 5
./nats/import_affs.sh 2>>errors.txt | tee -a run.log || exit 6
./nats/setup_scripts.sh 2>>errors.txt | tee -a run.log || exit 7
./nats/get_repos.sh 2>>errors.txt | tee -a run.log || exit 8
echo "All done. You should run ./nats/reinit.sh script now."
