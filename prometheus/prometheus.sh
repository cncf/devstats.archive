#!/bin/bash
# Run this script from the repository top level: ./prometheus/prometheus.sh
set -o pipefail
> errors.txt
> run.log
GHA2DB_PROJECT=prometheus IDB_DB=prometheus PG_DB=prometheus GHA2DB_LOCAL=1 ./structure 2>>errors.txt | tee -a run.log || exit 1
GHA2DB_PROJECT=prometheus IDB_DB=prometheus PG_DB=prometheus GHA2DB_LOCAL=1 ./gha2db 2015-01-01 0 today now 'prometheus' 2>>errors.txt | tee -a run.log || exit 2
GHA2DB_PROJECT=prometheus IDB_DB=prometheus PG_DB=prometheus GHA2DB_LOCAL=1 GHA2DB_OLDFMT=1 GHA2DB_EXACT=1 ./gha2db 2014-03-03 0 2014-12-31 23 'prometheus/prometheus' 2>>errors.txt | tee -a run.log || exit 3
GHA2DB_PROJECT=prometheus IDB_DB=prometheus PG_DB=prometheus GHA2DB_LOCAL=1 GHA2DB_MGETC=y GHA2DB_SKIPTABLE=1 GHA2DB_INDEX=1 ./structure 2>>errors.txt | tee -a run.log || exit 4
./grafana/influxdb_recreate.sh prometheus
./prometheus/setup_repo_groups.sh 2>>errors.txt | tee -a run.log || exit 6
./prometheus/setup_scripts.sh 2>>errors.txt | tee -a run.log || exit 7
./prometheus/import_affs.sh 2>>errors.txt | tee -a run.log || exit 8
./prometheus/get_repos.sh 2>>errors.txt | tee -a run.log || exit 9
echo "All done. You should run ./prometheus/reinit.sh script now."
