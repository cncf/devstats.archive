#!/bin/bash
# Run this script from the repository top level: ./kubernetes/kubernetes_test.sh
set -o pipefail
> errors.txt
> run.log
GHA2DB_LOCAL=1 PG_DB=test GHA2DB_MGETC=y ./structure 2>>errors.txt | tee -a run.log || exit 1

GHA2DB_LOCAL=1 PG_DB=test ./gha2db 2017-08-29 0 2017-08-31 0 'kubernetes,kubernetes-client,kubernetes-incubator' 2>>errors.txt | tee -a run.log || exit 2
##echo "Finished 1st phase, press enter or ^c"
##read a

GHA2DB_LOCAL=1 PG_DB=test GHA2DB_EXACT=1 ./gha2db 2015-07-07 0 2015-07-09 0 'GoogleCloudPlatform/kubernetes,kubernetes,kubernetes-client' 2>>errors.txt | tee -a run.log || exit 3
##echo "Finished 2nd phase, press enter or ^c"
##read a

GHA2DB_LOCAL=1 PG_DB=test GHA2DB_OLDFMT=1 GHA2DB_EXACT=1 ./gha2db 2014-11-04 0 2014-11-06 0 'GoogleCloudPlatform/kubernetes,kubernetes,kubernetes-client' 2>>errors.txt | tee -a run.log || exit 4
##echo "Finished 3rd phase, press enter or ^c"
##read a

GHA2DB_LOCAL=1 PG_DB=test GHA2DB_MGETC=y GHA2DB_SKIPTABLE=1 GHA2DB_INDEX=1 ./structure 2>>errors.txt | tee -a run.log || exit 5
echo "All done."

# To test on unlimited repos
#GHA2DB_LOCAL=1 PG_DB=test ./gha2db 2017-08-29 0 2017-08-31 0 2>>errors.txt | tee -a run.log || exit 6
#GHA2DB_LOCAL=1 PG_DB=test GHA2DB_EXACT=1 ./gha2db 2015-07-07 0 2015-07-09 0 2>>errors.txt | tee -a run.log || exit 7
#GHA2DB_LOCAL=1 PG_DB=test GHA2DB_OLDFMT=1 ./gha2db 2014-11-04 0 2014-11-06 0 2>>errors.txt | tee -a run.log || exit 8
