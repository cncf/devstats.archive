#!/bin/bash
function finish {
    sync_unlock.sh
}
trap finish EXIT
sync_lock.sh
set -o pipefail
> errors.txt
> run.log
GHA2DB_PROJECT=jaeger IDB_DB=jaeger PG_DB=jaeger GHA2DB_LOCAL=1 ./structure 2>>errors.txt | tee -a run.log || exit 1
GHA2DB_PROJECT=jaeger IDB_DB=jaeger PG_DB=jaeger GHA2DB_LOCAL=1 ./gha2db 2016-11-01 0 today now 'jaegertracing,uber/jaeger' 2>>errors.txt | tee -a run.log || exit 2
GHA2DB_PROJECT=jaeger IDB_DB=jaeger PG_DB=jaeger GHA2DB_LOCAL=1 GHA2DB_MGETC=y GHA2DB_SKIPTABLE=1 GHA2DB_INDEX=1 ./structure 2>>errors.txt | tee -a run.log || exit 3
./grafana/influxdb_recreate.sh jaeger
./jaeger/setup_repo_groups.sh 2>>errors.txt | tee -a run.log || exit 4
./jaeger/import_affs.sh 2>>errors.txt | tee -a run.log || exit 5
./jaeger/setup_scripts.sh 2>>errors.txt | tee -a run.log || exit 6
./jaeger/get_repos.sh 2>>errors.txt | tee -a run.log || exit 7
echo "All done. You should run ./jaeger/reinit.sh script now."
