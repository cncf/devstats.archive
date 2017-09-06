#!/bin/sh
> errors.txt
> run.log
GHA2DB_MGETC=y ./structure 2>>errors.txt | tee -a run.log || exit 1
./gha2db 2015-08-01 0 today now 'kubernetes,kubernetes-client,kubernetes-incubator' 2>>errors.txt | tee -a run.log || exit 2
GHA2DB_EXACT=1 ./gha2db 2015-01-01 0 2016-01-01 0 'GoogleCloudPlatform/kubernetes,kubernetes,kubernetes-client' 2>>errors.txt | tee -a run.log || exit 3
GHA2DB_OLDFMT=1 GHA2DB_EXACT=1 ./gha2db 2014-06-01 0 2014-12-31 23 'GoogleCloudPlatform/kubernetes,kubernetes,kubernetes-client' 2>>errors.txt | tee -a run.log || exit 4
GHA2DB_MGETC=y GHA2DB_SKIPTABLE=1 GHA2DB_INDEX=1 ./structure 2>>errors.txt | tee -a run.log || exit 5
echo "All done."
