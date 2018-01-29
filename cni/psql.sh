#!/bin/bash
set -o pipefail
> errors.txt
> run.log
GHA2DB_PROJECT=cni IDB_DB=cni PG_DB=cni GHA2DB_LOCAL=1 ./structure 2>>errors.txt | tee -a run.log || exit 1
GHA2DB_PROJECT=cni IDB_DB=cni PG_DB=cni GHA2DB_LOCAL=1 ./gha2db 2016-05-04 0 today now 'containernetworking' 2>>errors.txt | tee -a run.log || exit 2
GHA2DB_PROJECT=cni IDB_DB=cni PG_DB=cni GHA2DB_LOCAL=1 GHA2DB_EXACT=1 ./gha2db 2015-04-04 0 2016-05-05 0 'appc/cni' 2>>errors.txt | tee -a run.log || exit 3
GHA2DB_PROJECT=cni IDB_DB=cni PG_DB=cni GHA2DB_LOCAL=1 GHA2DB_MGETC=y GHA2DB_SKIPTABLE=1 GHA2DB_INDEX=1 ./structure 2>>errors.txt | tee -a run.log || exit 4
./grafana/influxdb_recreate.sh cni
./cni/setup_repo_groups.sh 2>>errors.txt | tee -a run.log || exit 5
./cni/import_affs.sh 2>>errors.txt | tee -a run.log || exit 6
./cni/setup_scripts.sh 2>>errors.txt | tee -a run.log || exit 7
./cni/get_repos.sh 2>>errors.txt | tee -a run.log || exit 8
echo "All done. You should run ./cni/reinit.sh script now."
