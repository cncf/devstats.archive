#!/bin/bash
set -o pipefail
> errors.txt
> run.log

GHA2DB_LOCAL=1 PG_DB=cloudfoundry GHA2DB_MGETC=y ./structure 2>>errors.txt | tee -a run.log || exit 1
GHA2DB_LOCAL=1 PG_DB=cloudfoundry ./gha2db 2016-09-01 0 2017-10-01 0 'cloudfoundry,cloudfoundry-attic,cloudfoundry-community,cloudfoundry-incubator,cloudfoundry-samples' 2>>errors.txt | tee -a run.log || exit 2
GHA2DB_LOCAL=1 PG_DB=cloudfoundry GHA2DB_MGETC=y GHA2DB_SKIPTABLE=1 GHA2DB_INDEX=1 ./structure 2>>errors.txt | tee -a run.log || exit 5
echo "All done."
