#!/bin/bash
# Run this script from the repository top level: ./containerd/containerd.sh
set -o pipefail
> errors.txt
> run.log
GHA2DB_PROJECT=containerd IDB_DB=containerd PG_DB=containerd GHA2DB_LOCAL=1 ./structure 2>>errors.txt | tee -a run.log || exit 1
# Broken GitHub archive file 2017-11-08 1:00 AM: https://github.com/igrigorik/githubarchive.org/issues/169
GHA2DB_PROJECT=containerd IDB_DB=containerd PG_DB=containerd GHA2DB_LOCAL=1 ./gha2db 2015-12-04 0 2017-11-08 0 'containerd,docker/containerd' 2>>errors.txt | tee -a run.log || exit 2
GHA2DB_PROJECT=containerd IDB_DB=containerd PG_DB=containerd GHA2DB_LOCAL=1 ./gha2db 2017-11-08 2 today now 'containerd,docker/containerd' 2>>errors.txt | tee -a run.log || exit 3
GHA2DB_PROJECT=containerd IDB_DB=containerd PG_DB=containerd GHA2DB_LOCAL=1 GHA2DB_MGETC=y GHA2DB_SKIPTABLE=1 GHA2DB_INDEX=1 ./structure 2>>errors.txt | tee -a run.log || exit 4
./grafana/influxdb_recreate.sh containerd
./containerd/setup_repo_groups.sh 2>>errors.txt | tee -a run.log || exit 6
./containerd/import_affs.sh 2>>errors.txt | tee -a run.log || exit 7
echo "All done. You should run ./containerd/reinit.sh script now."
