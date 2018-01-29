#!/bin/bash
set -o pipefail
> errors.txt
> run.log
GHA2DB_PROJECT=all IDB_DB=allprj PG_DB=allprj GHA2DB_LOCAL=1 ./structure 2>>errors.txt | tee -a run.log || exit 1
PG_DB=allprj GHA2DB_LOCAL=1 ./runq ./scripts/all/merge_all_projects.sql 2>>errors.txt | tee -a run.log || exit 1
GHA2DB_PROJECT=all IDB_DB=allprj PG_DB=allprj GHA2DB_LOCAL=1 GHA2DB_MGETC=y GHA2DB_SKIPTABLE=1 GHA2DB_INDEX=1 ./structure 2>>errors.txt | tee -a run.log || exit 3
#./grafana/influxdb_recreate.sh allprj
./all/setup_scripts.sh 2>>errors.txt | tee -a run.log || exit 5
#./all/import_affs.sh 2>>errors.txt | tee -a run.log || exit 6
#./all/get_repos.sh 2>>errors.txt | tee -a run.log || exit 7
echo "All done. You should run ./all/reinit.sh script now."
