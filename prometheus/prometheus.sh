#!/bin/bash
# Run this script from the repository top level: ./prometheus/prometheus.sh
set -o pipefail
> errors.txt
> run.log
PG_DB=prometheus GHA2DB_LOCAL=1 ./structure 2>>errors.txt | tee -a run.log || exit 1
PG_DB=prometheus GHA2DB_LOCAL=1 ./gha2db 2015-01-01 0 today now 'prometheus' 2>>errors.txt | tee -a run.log || exit 2
PG_DB=prometheus GHA2DB_LOCAL=1 GHA2DB_OLDFMT=1 GHA2DB_EXACT=1 ./gha2db 2014-03-03 0 2014-12-31 23 'prometheus/prometheus' 2>>errors.txt | tee -a run.log || exit 3
PG_DB=prometheus GHA2DB_LOCAL=1 GHA2DB_MGETC=y GHA2DB_SKIPTABLE=1 GHA2DB_INDEX=1 ./structure 2>>errors.txt | tee -a run.log || exit 4
PG_DB=prometheus GHA2DB_LOCAL=1 ./import_affs github_users.json 2>>errors.txt | tee -a run.log || exit 5
./prometheus/setup_repo_groups.sh 2>>errors.txt | tee -a run.log || exit 6
echo "All done."
