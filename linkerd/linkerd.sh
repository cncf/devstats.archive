#!/bin/bash
# Run this script from the repository top level: ./linkerd/linkerd.sh
set -o pipefail
> errors.txt
> run.log
GHA2DB_PROJECT=linkerd IDB_DB=linkerd PG_DB=linkerd GHA2DB_LOCAL=1 ./structure 2>>errors.txt | tee -a run.log || exit 1
GHA2DB_PROJECT=linkerd IDB_DB=linkerd PG_DB=linkerd GHA2DB_LOCAL=1 ./gha2db 2017-01-23 0 today now 'linkerd' 2>>errors.txt | tee -a run.log || exit 2
GHA2DB_PROJECT=linkerd IDB_DB=linkerd PG_DB=linkerd GHA2DB_LOCAL=1 GHA2DB_EXACT=1 ./gha2db 2016-01-13 0 2017-01-24 0 'BuoyantIO/linkerd' 2>>errors.txt | tee -a run.log || exit 2
GHA2DB_PROJECT=linkerd IDB_DB=linkerd PG_DB=linkerd GHA2DB_LOCAL=1 GHA2DB_MGETC=y GHA2DB_SKIPTABLE=1 GHA2DB_INDEX=1 ./structure 2>>errors.txt | tee -a run.log || exit 4
./grafana/influxdb_recreate.sh linkerd
./linkerd/setup_repo_groups.sh 2>>errors.txt | tee -a run.log || exit 6
./linkerd/import_affs.sh 2>>errors.txt | tee -a run.log || exit 7
./linkerd/setup_scripts.sh 2>>errors.txt | tee -a run.log || exit 8
echo "All done. You should run ./linkerd/reinit.sh script now."
