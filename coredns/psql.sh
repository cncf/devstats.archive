#!/bin/bash
function finish {
    sync_unlock.sh
}
trap finish EXIT
sync_lock.sh
set -o pipefail
> errors.txt
> run.log
GHA2DB_PROJECT=coredns IDB_DB=coredns PG_DB=coredns GHA2DB_LOCAL=1 ./structure 2>>errors.txt | tee -a run.log || exit 1
GHA2DB_PROJECT=coredns IDB_DB=coredns PG_DB=coredns GHA2DB_LOCAL=1 ./gha2db 2016-03-18 0 today now 'miekg/coredns,coredns' 2>>errors.txt | tee -a run.log || exit 2
GHA2DB_PROJECT=coredns IDB_DB=coredns PG_DB=coredns GHA2DB_LOCAL=1 GHA2DB_MGETC=y GHA2DB_SKIPTABLE=1 GHA2DB_INDEX=1 ./structure 2>>errors.txt | tee -a run.log || exit 3
./grafana/influxdb_recreate.sh coredns
./coredns/setup_repo_groups.sh 2>>errors.txt | tee -a run.log || exit 4
./coredns/import_affs.sh 2>>errors.txt | tee -a run.log || exit 5
./coredns/setup_scripts.sh 2>>errors.txt | tee -a run.log || exit 6
./coredns/get_repos.sh 2>>errors.txt | tee -a run.log || exit 7
echo "All done. You should run ./coredns/reinit.sh script now."
