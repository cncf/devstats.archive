#!/bin/bash
# Run this script from the repository top level: ./rkt/rkt.sh
set -o pipefail
> errors.txt
> run.log
GHA2DB_PROJECT=rkt IDB_DB=rkt PG_DB=rkt GHA2DB_LOCAL=1 ./structure 2>>errors.txt | tee -a run.log || exit 1
# Broken GitHub archive file 2017-11-08 1:00 AM: https://github.com/igrigorik/githubarchive.org/issues/169
GHA2DB_PROJECT=rkt IDB_DB=rkt PG_DB=rkt GHA2DB_LOCAL=1 ./gha2db 2017-04-04 0 2017-11-08 0 'rkt' 2>>errors.txt | tee -a run.log || exit 2
GHA2DB_PROJECT=rkt IDB_DB=rkt PG_DB=rkt GHA2DB_LOCAL=1 ./gha2db 2017-11-08 2 today now 'rkt' 2>>errors.txt | tee -a run.log || exit 3
GHA2DB_PROJECT=rkt IDB_DB=rkt PG_DB=rkt GHA2DB_LOCAL=1 GHA2DB_EXACT=1 ./gha2db 2015-01-01 0 2017-04-07 0 'coreos/rkt,coreos/rocket,rktproject/rkt' 2>>errors.txt | tee -a run.log || exit 4
GHA2DB_PROJECT=rkt IDB_DB=rkt PG_DB=rkt GHA2DB_LOCAL=1 GHA2DB_EXACT=1 GHA2DB_OLDFMT=1 ./gha2db 2014-11-26 0 2014-12-31 23 'rocket' 2>>errors.txt | tee -a run.log || exit 5
GHA2DB_PROJECT=rkt IDB_DB=rkt PG_DB=rkt GHA2DB_LOCAL=1 GHA2DB_MGETC=y GHA2DB_SKIPTABLE=1 GHA2DB_INDEX=1 ./structure 2>>errors.txt | tee -a run.log || exit 6
./grafana/influxdb_recreate.sh rkt
./rkt/setup_repo_groups.sh 2>>errors.txt | tee -a run.log || exit 7
./rkt/import_affs.sh 2>>errors.txt | tee -a run.log || exit 8
./rkt/setup_scripts.sh 2>>errors.txt | tee -a run.log || exit 9
echo "All done. You should run ./rkt/reinit.sh script now."
