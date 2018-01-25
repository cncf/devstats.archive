#!/bin/bash
# Run this script from the repository top level: ./fluentd/fluentd.sh
set -o pipefail
> errors.txt
> run.log
GHA2DB_PROJECT=fluentd IDB_DB=fluentd PG_DB=fluentd GHA2DB_LOCAL=1 ./structure 2>>errors.txt | tee -a run.log || exit 1
# Broken GitHub archive file 2017-11-08 1:00 AM: https://github.com/igrigorik/githubarchive.org/issues/169
GHA2DB_PROJECT=fluentd IDB_DB=fluentd PG_DB=fluentd GHA2DB_LOCAL=1 ./gha2db 2015-01-01 0 2017-11-08 0 'fluent' 2>>errors.txt | tee -a run.log || exit 2
GHA2DB_PROJECT=fluentd IDB_DB=fluentd PG_DB=fluentd GHA2DB_LOCAL=1 ./gha2db 2017-11-08 2 today now 'fluent' 2>>errors.txt | tee -a run.log || exit 3
GHA2DB_PROJECT=fluentd IDB_DB=fluentd PG_DB=fluentd GHA2DB_LOCAL=1 GHA2DB_EXACT=1 GHA2DB_OLDFMT=1 ./gha2db 2014-01-02 0 2014-12-31 23 'fluent' 2>>errors.txt | tee -a run.log || exit 4
GHA2DB_PROJECT=fluentd IDB_DB=fluentd PG_DB=fluentd GHA2DB_LOCAL=1 GHA2DB_MGETC=y GHA2DB_SKIPTABLE=1 GHA2DB_INDEX=1 ./structure 2>>errors.txt | tee -a run.log || exit 5
./grafana/influxdb_recreate.sh fluentd
./fluentd/setup_repo_groups.sh 2>>errors.txt | tee -a run.log || exit 6
./fluentd/setup_scripts.sh 2>>errors.txt | tee -a run.log || exit 7
./fluentd/import_affs.sh 2>>errors.txt | tee -a run.log || exit 8
./fluentd/get_repos.sh 2>>errors.txt | tee -a run.log || exit 9
echo "All done. You should run ./fluentd/reinit.sh script now."
