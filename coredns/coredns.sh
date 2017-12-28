#!/bin/bash
# Run this script from the repository top level: ./coredns/coredns.sh
set -o pipefail
> errors.txt
> run.log
GHA2DB_PROJECT=coredns IDB_DB=coredns PG_DB=coredns GHA2DB_LOCAL=1 ./structure 2>>errors.txt | tee -a run.log || exit 1
# Broken GitHub archive file 2017-11-08 1:00 AM: https://github.com/igrigorik/githubarchive.org/issues/169
GHA2DB_PROJECT=coredns IDB_DB=coredns PG_DB=coredns GHA2DB_LOCAL=1 ./gha2db 2017-02-21 0 2017-11-08 0 'coredns' 2>>errors.txt | tee -a run.log || exit 2
GHA2DB_PROJECT=coredns IDB_DB=coredns PG_DB=coredns GHA2DB_LOCAL=1 ./gha2db 2017-11-08 2 today now 'coredns' 2>>errors.txt | tee -a run.log || exit 2
GHA2DB_PROJECT=coredns IDB_DB=coredns PG_DB=coredns GHA2DB_LOCAL=1 GHA2DB_MGETC=y GHA2DB_SKIPTABLE=1 GHA2DB_INDEX=1 ./structure 2>>errors.txt | tee -a run.log || exit 4
./grafana/influxdb_recreate.sh coredns
./coredns/setup_repo_groups.sh 2>>errors.txt | tee -a run.log || exit 6
./coredns/import_affs.sh 2>>errors.txt | tee -a run.log || exit 7
echo "All done. You should run ./coredns/reinit.sh script now."
